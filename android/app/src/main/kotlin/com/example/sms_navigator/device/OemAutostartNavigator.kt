package com.example.sms_navigator.device

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

class OemAutostartNavigator(private val context: Context) {

    private data class OemAutoStartSettings(
        val oemKey: String,
        val brandKeywords: List<String>,
        val components: List<ComponentName>
    )

    private val aggressiveOemSettings = listOf(
        OemAutoStartSettings(
            oemKey = "xiaomi",
            brandKeywords = listOf("xiaomi", "redmi", "poco"),
            components = listOf(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            )
        ),
        OemAutoStartSettings(
            oemKey = "oppo",
            brandKeywords = listOf("oppo", "realme", "oneplus"),
            components = listOf(
                ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                ),
                ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity"
                ),
                ComponentName(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.startup.StartupAppListActivity"
                ),
                ComponentName(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity"
                )
            )
        ),
        OemAutoStartSettings(
            oemKey = "vivo",
            brandKeywords = listOf("vivo", "iqoo"),
            components = listOf(
                ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                ),
                ComponentName(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                ),
                ComponentName(
                    "com.iqoo.secure",
                    "com.iqoo.secure.safeguard.PurviewTabActivity"
                )
            )
        ),
        OemAutoStartSettings(
            oemKey = "huawei",
            brandKeywords = listOf("huawei", "honor", "hihonor"),
            components = listOf(
                ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                ),
                ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity"
                ),
                ComponentName(
                    "com.hihonor.systemmanager",
                    "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
            )
        ),
        OemAutoStartSettings(
            oemKey = "samsung",
            brandKeywords = listOf("samsung"),
            components = listOf(
                ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"
                ),
                ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity"
                ),
                ComponentName(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"
                ),
                ComponentName(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.battery.ui.BatteryActivity"
                )
            )
        )
    )

    fun detectAggressiveOem(): String? {
        val manufacturer = Build.MANUFACTURER?.lowercase() ?: ""
        val brand = Build.BRAND?.lowercase() ?: ""
        val keywords = "$manufacturer $brand"
        return aggressiveOemSettings
            .firstOrNull { oem -> oem.brandKeywords.any { keywords.contains(it) } }
            ?.oemKey
    }

    fun openAutostartSettings(): Boolean {
        val oemKey = detectAggressiveOem() ?: return false
        val oem = aggressiveOemSettings.firstOrNull { it.oemKey == oemKey }
            ?: return false
        for (component in oem.components) {
            try {
                val intent = Intent().apply {
                    this.component = component
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                return true
            } catch (e: Exception) {
                continue
            }
        }
        return false
    }

    fun openAppDetailsSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }
}
