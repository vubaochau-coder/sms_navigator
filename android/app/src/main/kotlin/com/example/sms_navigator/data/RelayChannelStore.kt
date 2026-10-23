package com.example.sms_navigator.data

import org.json.JSONArray
import org.json.JSONObject

/** Mã hóa at-rest cho channel key. Tách interface để unit test JVM không cần Android Keystore. */
interface KeyVault {
    fun encrypt(plaintext: String): String
    fun decrypt(blob: String): String
}

object SecureVaultKeyVault : KeyVault {
    override fun encrypt(plaintext: String): String = SecureVault.encryptToBase64(plaintext)
    override fun decrypt(blob: String): String = SecureVault.decryptFromBase64(blob)
}

/**
 * Một kênh Owner mà thiết bị này relay SMS tới.
 *
 * - [activeEpoch]: epoch đang dùng để mã hóa (0 = chưa có key dùng được).
 * - [pendingEpoch]: key đã "stage" trước khi server commit rotation (xem
 *   [RelayChannelStore.stageKey]); worker dùng nó để tự phục hồi khi gặp
 *   409 EPOCH_OUTDATED mà app không chạy.
 */
data class RelayChannel(
    val channelId: String,
    val name: String,
    val activeEpoch: Long,
    val pendingEpoch: Long?,
    val keys: Map<Long, String>
) {
    val activeKey: String? get() = keys[activeEpoch]
    fun keyFor(epoch: Long): String? = keys[epoch]
}

/** Đầu vào của [RelayChannelStore.replaceAll] — trạng thái server-truth do Dart gửi xuống. */
data class RelayChannelSnapshot(
    val channelId: String,
    val name: String,
    val epoch: Long,
    val keyBase64: String
)

/** SMS chưa relay được vì thiếu key epoch mới — chờ app mở để đồng bộ rồi gửi lại. */
data class ParkedMessage(
    val messageId: String,
    val channelId: String,
    val sender: String,
    val messageText: String,
    val parkedAt: Long,
    /** Một SMS nhận được → một smsId, dùng chung cho mọi kênh — nhật ký relay gom theo nó. */
    val smsId: String = ""
)

/**
 * Kho cấu hình relay đa kênh (thay cho "active channel" đơn lẻ trước đây).
 *
 * Mọi thao tác ghi dùng `commit()` (đồng bộ) vì đây là dữ liệu khóa: mất một
 * lần ghi do process bị kill sẽ làm worker mã hóa sai epoch. Khóa toàn cục
 * [LOCK] vì receiver, worker và MethodChannel mỗi nơi tạo một instance riêng.
 */
class RelayChannelStore(
    private val otpPrefs: OtpPreferences,
    private val vault: KeyVault = SecureVaultKeyVault,
    private val clock: () -> Long = System::currentTimeMillis
) {
    private val prefs get() = otpPrefs.prefs

    fun all(): List<RelayChannel> = synchronized(LOCK) {
        migrateLegacyIfNeeded()
        readChannels().values.toList()
    }

    fun get(channelId: String): RelayChannel? = synchronized(LOCK) {
        migrateLegacyIfNeeded()
        readChannels()[channelId]
    }

    /**
     * Đồng bộ toàn bộ danh sách kênh Owner từ Dart. Kênh không có trong
     * [snapshot] bị xóa. Với kênh còn lại: không bao giờ hạ epoch (snapshot có
     * thể được đọc trước một rotation vừa promote), và giữ key pending nếu nó
     * mới hơn epoch của snapshot. Kênh trong [retainIds] (Dart không lấy được
     * key lượt này) giữ nguyên trạng thái hiện có thay vì bị xóa.
     */
    fun replaceAll(snapshot: List<RelayChannelSnapshot>, retainIds: Collection<String> = emptyList()) = synchronized(LOCK) {
        migrateLegacyIfNeeded()
        val existing = readChannels()
        val next = LinkedHashMap<String, RelayChannel>()
        for (id in retainIds) {
            existing[id]?.let { next[id] = it }
        }
        for (item in snapshot) {
            if (item.channelId.isBlank() || item.keyBase64.isBlank()) continue
            val old = existing[item.channelId]
            val keys = HashMap(old?.keys ?: emptyMap())
            keys[item.epoch] = item.keyBase64
            val active = maxOf(old?.activeEpoch ?: 0L, item.epoch).takeIf { keys.containsKey(it) } ?: item.epoch
            val pending = old?.pendingEpoch?.takeIf { it > active && keys.containsKey(it) }
            next[item.channelId] = prune(
                RelayChannel(item.channelId, item.name.ifBlank { old?.name ?: "" }, active, pending, keys)
            )
        }
        writeChannels(next)
    }

    /** Lưu key epoch mới TRƯỚC khi gọi server rotate. Chưa dùng để mã hóa cho tới khi promote. */
    fun stageKey(channelId: String, name: String?, epoch: Long, keyBase64: String) = synchronized(LOCK) {
        migrateLegacyIfNeeded()
        val channels = readChannels()
        val old = channels[channelId]
        val keys = HashMap(old?.keys ?: emptyMap())
        keys[epoch] = keyBase64
        channels[channelId] = prune(
            RelayChannel(
                channelId = channelId,
                name = name?.takeIf { it.isNotBlank() } ?: old?.name ?: "",
                activeEpoch = old?.activeEpoch ?: 0L,
                pendingEpoch = epoch,
                keys = keys
            )
        )
        writeChannels(channels)
    }

    /** Server đã commit [epoch]: chuyển sang dùng key đó. Trả false nếu không có key cho epoch này. */
    fun promoteKey(channelId: String, epoch: Long): Boolean = synchronized(LOCK) {
        val channels = readChannels()
        val old = channels[channelId] ?: return@synchronized false
        if (!old.keys.containsKey(epoch)) return@synchronized false
        if (epoch < old.activeEpoch) return@synchronized true
        channels[channelId] = prune(
            old.copy(activeEpoch = epoch, pendingEpoch = old.pendingEpoch?.takeIf { it > epoch })
        )
        writeChannels(channels)
        true
    }

    /** Rotation bị server từ chối dứt khoát: bỏ key pending. */
    fun discardKey(channelId: String, epoch: Long) = synchronized(LOCK) {
        val channels = readChannels()
        val old = channels[channelId] ?: return@synchronized
        if (old.pendingEpoch != epoch || epoch == old.activeEpoch) return@synchronized
        val keys = HashMap(old.keys).apply { remove(epoch) }
        if (old.activeEpoch == 0L && keys.isEmpty()) {
            channels.remove(channelId)
        } else {
            channels[channelId] = old.copy(pendingEpoch = null, keys = keys)
        }
        writeChannels(channels)
    }

    fun remove(channelId: String) {
        synchronized(LOCK) {
            val channels = readChannels()
            if (channels.remove(channelId) != null) writeChannels(channels)
        }
    }

    // ------------------------------------------------------------ parked queue

    fun park(message: ParkedMessage) = synchronized(LOCK) {
        val list = readParked().filterNot { it.messageId == message.messageId }.toMutableList()
        list.add(message)
        writeParked(list.takeLast(MAX_PARKED))
    }

    /** Lấy và xóa toàn bộ tin đang chờ (bỏ tin quá [PARKED_TTL_MS] — OTP đã hết hạn). */
    fun drainParked(): List<ParkedMessage> = synchronized(LOCK) {
        val now = clock()
        val list = readParked().filter { now - it.parkedAt < PARKED_TTL_MS }
        prefs.edit().remove(KEY_PARKED).commit()
        list
    }

    fun parkedCount(): Int = synchronized(LOCK) { readParked().size }

    // ------------------------------------------------------------- outbox (2.1)
    //
    // Nội dung SMS đang chờ worker gửi. Trước đây text nằm thẳng trong
    // `inputData` của WorkManager (SQLite không mã hoá) cho tới khi worker
    // xong — tối đa 5 lần retry. Giờ text + sender được mã hoá bằng [vault]
    // ở đây, worker chỉ nhận [outboxId].

    /** Lưu tin chờ gửi; trả về id để đưa vào WorkManager. Ghi đè nếu đã có. */
    fun putOutbox(message: ParkedMessage): String = synchronized(LOCK) {
        val id = outboxId(message.channelId, message.messageId)
        val now = clock()
        val entries = readOutbox().filterValues { now - it.parkedAt < PARKED_TTL_MS }.toMutableMap()
        entries.remove(id)
        entries[id] = message
        // Giữ [MAX_OUTBOX] tin mới nhất (LinkedHashMap giữ thứ tự chèn).
        val trimmed = entries.entries.toList().takeLast(MAX_OUTBOX).associate { it.key to it.value }
        writeOutbox(trimmed)
        id
    }

    fun getOutbox(id: String): ParkedMessage? = synchronized(LOCK) { readOutbox()[id] }

    fun removeOutbox(id: String) = synchronized(LOCK) {
        val entries = readOutbox()
        if (entries.remove(id) != null) writeOutbox(entries)
    }

    fun outboxCount(): Int = synchronized(LOCK) { readOutbox().size }

    // ------------------------------------------------------------- internals

    /** Giữ key active, pending và tối đa [KEEP_PREVIOUS_EPOCHS] epoch cũ ngay trước active. */
    private fun prune(channel: RelayChannel): RelayChannel {
        val keep = mutableSetOf<Long>()
        keep.add(channel.activeEpoch)
        channel.pendingEpoch?.let { keep.add(it) }
        channel.keys.keys.filter { it < channel.activeEpoch }
            .sortedDescending().take(KEEP_PREVIOUS_EPOCHS).forEach { keep.add(it) }
        return channel.copy(keys = channel.keys.filterKeys { it in keep })
    }

    /** Lần đầu sau khi cập nhật app: chuyển cấu hình "active channel" cũ sang store đa kênh. */
    private fun migrateLegacyIfNeeded() {
        if (prefs.contains(KEY_CHANNELS)) return
        val legacyId = otpPrefs.activeChannelId
        val legacyKey = otpPrefs.activeChannelKeyBase64
        val channels = LinkedHashMap<String, RelayChannel>()
        if (!legacyId.isNullOrBlank() && !legacyKey.isNullOrBlank()) {
            val epoch = otpPrefs.activeChannelEpoch
            channels[legacyId] = RelayChannel(
                channelId = legacyId,
                name = otpPrefs.activeChannelName ?: "",
                activeEpoch = epoch,
                pendingEpoch = null,
                keys = mapOf(epoch to legacyKey)
            )
        }
        writeChannels(channels)
        otpPrefs.clearActiveRelayChannel()
    }

    private fun readChannels(): LinkedHashMap<String, RelayChannel> {
        val result = LinkedHashMap<String, RelayChannel>()
        val raw = prefs.getString(KEY_CHANNELS, null) ?: return result
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val id = obj.optString("id")
                if (id.isBlank()) continue
                val keys = HashMap<Long, String>()
                val keysObj = obj.optJSONObject("keys") ?: JSONObject()
                val epochIter = keysObj.keys()
                while (epochIter.hasNext()) {
                    val epochStr = epochIter.next()
                    val epoch = epochStr.toLongOrNull() ?: continue
                    val decrypted = decryptOrNull(keysObj.optString(epochStr)) ?: continue
                    keys[epoch] = decrypted
                }
                val pending = if (obj.has("pending_epoch") && !obj.isNull("pending_epoch")) obj.optLong("pending_epoch") else null
                result[id] = RelayChannel(
                    channelId = id,
                    name = obj.optString("name"),
                    activeEpoch = obj.optLong("active_epoch", 0L),
                    pendingEpoch = pending,
                    keys = keys
                )
            }
        } catch (_: Exception) {
            // Dữ liệu hỏng → coi như rỗng; Dart reconcile sẽ ghi lại toàn bộ.
        }
        return result
    }

    private fun writeChannels(channels: Map<String, RelayChannel>) {
        val array = JSONArray()
        for (channel in channels.values) {
            val keysObj = JSONObject()
            channel.keys.forEach { (epoch, key) -> keysObj.put(epoch.toString(), encrypt(key)) }
            array.put(
                JSONObject().apply {
                    put("id", channel.channelId)
                    put("name", channel.name)
                    put("active_epoch", channel.activeEpoch)
                    put("pending_epoch", channel.pendingEpoch ?: JSONObject.NULL)
                    put("keys", keysObj)
                }
            )
        }
        prefs.edit().putString(KEY_CHANNELS, array.toString()).commit()
    }

    private fun readParked(): List<ParkedMessage> {
        val raw = prefs.getString(KEY_PARKED, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                val obj = array.optJSONObject(i) ?: return@mapNotNull null
                val text = decryptOrNull(obj.optString("text")) ?: return@mapNotNull null
                ParkedMessage(
                    messageId = obj.optString("message_id"),
                    channelId = obj.optString("channel_id"),
                    sender = obj.optString("sender"),
                    messageText = text,
                    parkedAt = obj.optLong("parked_at"),
                    smsId = obj.optString("sms_id")
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun writeParked(list: List<ParkedMessage>) {
        val array = JSONArray()
        list.forEach { m ->
            array.put(
                JSONObject().apply {
                    put("message_id", m.messageId)
                    put("channel_id", m.channelId)
                    put("sender", m.sender)
                    put("text", encrypt(m.messageText))
                    put("parked_at", m.parkedAt)
                    put("sms_id", m.smsId)
                }
            )
        }
        prefs.edit().putString(KEY_PARKED, array.toString()).commit()
    }

    private fun readOutbox(): LinkedHashMap<String, ParkedMessage> {
        val result = LinkedHashMap<String, ParkedMessage>()
        val raw = prefs.getString(KEY_OUTBOX, null) ?: return result
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val id = obj.optString("id")
                val text = decryptOrNull(obj.optString("text")) ?: continue
                if (id.isBlank()) continue
                result[id] = ParkedMessage(
                    messageId = obj.optString("message_id"),
                    channelId = obj.optString("channel_id"),
                    sender = decryptOrNull(obj.optString("sender")) ?: "",
                    messageText = text,
                    parkedAt = obj.optLong("created_at"),
                    smsId = obj.optString("sms_id")
                )
            }
        } catch (_: Exception) {
            // Hỏng → rỗng; worker sẽ báo thiếu nội dung và dừng.
        }
        return result
    }

    private fun writeOutbox(entries: Map<String, ParkedMessage>) {
        val array = JSONArray()
        entries.forEach { (id, m) ->
            array.put(
                JSONObject().apply {
                    put("id", id)
                    put("message_id", m.messageId)
                    put("channel_id", m.channelId)
                    put("sender", encrypt(m.sender))
                    put("text", encrypt(m.messageText))
                    put("created_at", m.parkedAt)
                    put("sms_id", m.smsId)
                }
            )
        }
        prefs.edit().putString(KEY_OUTBOX, array.toString()).commit()
    }

    // Cùng chính sách với OtpPreferences: nếu Keystore lỗi thì lưu thô thay vì
    // làm hỏng relay (một số ROM có Keystore không ổn định) — và ghi lại để Dart
    // báo Crashlytics + cảnh báo (BACKLOG 2.2).
    private fun encrypt(value: String): String = try {
        vault.encrypt(value)
    } catch (e: Exception) {
        VaultFallbackLog.record(prefs, "relay_store", e)
        value
    }
    private fun decryptOrNull(value: String?): String? {
        if (value.isNullOrEmpty()) return null
        return try { vault.decrypt(value) } catch (_: Exception) { value }
    }

    companion object {
        private val LOCK = Any()
        private const val KEY_CHANNELS = "relay_channels_v1"
        private const val KEY_PARKED = "relay_parked_v1"
        private const val KEY_OUTBOX = "relay_outbox_v1"
        const val MAX_OUTBOX = 200

        fun outboxId(channelId: String, messageId: String): String = "$channelId|$messageId"
        const val KEEP_PREVIOUS_EPOCHS = 1
        const val MAX_PARKED = 50
        const val PARKED_TTL_MS = 24 * 60 * 60 * 1000L
    }
}
