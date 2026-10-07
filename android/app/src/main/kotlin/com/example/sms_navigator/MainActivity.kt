package com.example.sms_navigator

import com.example.sms_navigator.channel.RelayMethodChannel
import com.example.sms_navigator.data.OtpPreferences
import com.example.sms_navigator.device.OemAutostartNavigator
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
    }

    override fun onDestroy() {
        relayChannel?.unregister()
        relayChannel = null
        super.onDestroy()
    }
}
