package com.example.sms_navigator.policy

/**
 * Chuẩn hóa và so khớp địa chỉ người gửi (đầu số / brandname).
 * - Đầu số: so khớp prefix sau khi chuẩn hóa +84 / 84 / 0084 / 0 về cùng hệ quy chiếu.
 * - Brandname (chứa chữ cái): exact match, không phân biệt hoa thường — chống giả mạo dạng "VCB_PROMO".
 */
object PhoneNormalizer {

    private val SEPARATOR_REGEX = Regex("""[\s\-\(\)]""")

    fun clean(raw: String): String = raw.replace(SEPARATOR_REGEX, "").trim()

    fun isBrandname(raw: String): Boolean = clean(raw).any { it.isLetter() }

    /**
     * Về dạng quốc gia: "+84987654321" / "84987654321" / "0084987654321" -> "0987654321".
     * Đầu số ngắn (6147, 1900, 1069...) giữ nguyên.
     */
    fun normalizeNumber(raw: String): String {
        var s = clean(raw).removePrefix("+")
        if (s.startsWith("0084")) {
            s = "0" + s.substring(4)
        }
        if (s.startsWith("84") && s.length == 11 && s.substring(2).all { it.isDigit() }) {
            s = "0" + s.substring(2)
        }
        return s
    }

    private fun numericVariants(raw: String): Set<String> {
        val cleaned = clean(raw).removePrefix("+")
        val variants = mutableSetOf(cleaned)
        val national = normalizeNumber(raw)
        variants.add(national)
        if (national.startsWith("0")) {
            variants.add("84" + national.substring(1))
        }
        return variants
    }

    fun matches(sender: String, entry: String): Boolean {
        val cleanSender = clean(sender)
        val cleanEntry = clean(entry)
        if (cleanSender.isEmpty() || cleanEntry.isEmpty()) return false

        return if (isBrandname(cleanEntry)) {
            cleanSender.equals(cleanEntry, ignoreCase = true)
        } else {
            val senderVariants = numericVariants(sender)
            val entryVariants = numericVariants(entry)
            senderVariants.any { s -> entryVariants.any { e -> s.startsWith(e) } }
        }
    }
}
