package com.example.sms_navigator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.sms_navigator.data.OtpPreferences

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.i(TAG, "Device rebooted. Initializing OTP Relay status...")
            val prefs = OtpPreferences(context)
            Log.i(TAG, "Relay enabled: ${prefs.isRelayEnabled}, Paired: ${prefs.pairId != null}")
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
