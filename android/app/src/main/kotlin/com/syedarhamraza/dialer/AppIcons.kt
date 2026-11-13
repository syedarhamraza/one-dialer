package com.syedarhamraza.dialer

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

/** Runs [AppIcons.repair] after each update, before the app is opened. */
class AppIconsRepairReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) AppIcons.repair(context)
    }
}

object AppIcons {
    /**
     * Turns the launcher icon back on if it was switched off. Earlier versions had a Classic icon
     * (and a Contacts one) in Settings › App icon and disabled this one while Classic was chosen;
     * with Classic gone the app would otherwise have no launcher icon.
     */
    fun repair(context: Context) {
        val pm = context.packageManager
        val icon = ComponentName(context, "com.syedarhamraza.dialer.PhoneIcon")
        if (pm.getComponentEnabledSetting(icon) == PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
            pm.setComponentEnabledSetting(icon, PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, PackageManager.DONT_KILL_APP)
        }
    }
}
