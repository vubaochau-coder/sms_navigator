package com.example.sms_navigator

import android.content.Intent
import com.example.sms_navigator.channel.BackupFileChannel
import com.example.sms_navigator.channel.RelayMethodChannel
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.device.OemAutostartNavigator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var relayChannel: RelayMethodChannel? = null
    private var backupFileChannel: BackupFileChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = OtpPreferences(this)
        val deviceNavigator = OemAutostartNavigator(this)
        relayChannel = RelayMethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
            prefs,
            deviceNavigator
        )
        relayChannel?.register()

        backupFileChannel = BackupFileChannel(flutterEngine.dartExecutor.binaryMessenger, this)
        backupFileChannel?.register()
    }

    /** Kết quả SAF của [BackupFileChannel]; mọi request khác giữ hành vi mặc định. */
    @Suppress("DEPRECATION")
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupFileChannel?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        relayChannel?.unregister()
        relayChannel = null
        backupFileChannel?.unregister()
        backupFileChannel = null
        super.onDestroy()
    }
}
