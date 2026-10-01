package com.example.sms_navigator

import com.example.sms_navigator.channel.RelayMethodChannel
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.device.OemAutostartNavigator
import com.example.sms_navigator.receiver.SmsReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var relayChannel: RelayMethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = OtpPreferences(this)
        val deviceNavigator = OemAutostartNavigator(this)
        relayChannel = RelayMethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            prefs,
            deviceNavigator
        )
        relayChannel?.register()

        SmsReceiver.onOtpProcessedListener = { sender, otp ->
            relayChannel?.notifyOtpDetected(sender, otp)
        }
    }

    override fun onDestroy() {
        SmsReceiver.onOtpProcessedListener = null
        relayChannel?.unregister()
        relayChannel = null
        super.onDestroy()
    }
}
