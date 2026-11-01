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

/**
 * Settings › App icon: the Phone and Contacts launcher icons switch together between Glossy (the
 * default) and Classic. Each style is a pair of activity-aliases in the manifest; only the chosen
 * pair is enabled. The enabled alias is the only record of the choice.
 */
object AppIcons {
    const val DEFAULT = "default"
    val STYLES = listOf(DEFAULT, "classic")

    private fun suffix(style: String) = if (style == DEFAULT) "" else style.replaceFirstChar(Char::uppercase)

    private fun aliases(context: Context, style: String) = listOf(
        ComponentName(context, "com.syedarhamraza.dialer.PhoneIcon${suffix(style)}"),
        // The default Contacts icon keeps its original name, so home-screen shortcuts to it survive.
        ComponentName(context, "com.syedarhamraza.dialer.${if (style == DEFAULT) "ContactsLauncher" else "ContactsIcon${suffix(style)}"}"),
    )

    private fun enabled(pm: PackageManager, component: ComponentName, byDefault: Boolean) =
        when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> byDefault
            else -> false
        }

    fun current(context: Context): String = STYLES.firstOrNull { style ->
        enabled(context.packageManager, aliases(context, style)[0], byDefault = style == DEFAULT)
    } ?: DEFAULT

    /**
     * Turns the chosen style's pair back on if either is off, falling back to the default. An
     * update that drops a style (or a half-finished switch) would otherwise leave no launcher
     * icon, and Android then shows a stand-in that opens App info.
     */
    fun repair(context: Context) {
        val pm = context.packageManager
        val style = current(context)
        if (aliases(context, style).any { !enabled(pm, it, byDefault = style == DEFAULT) }) set(context, style)
    }

    fun set(context: Context, style: String) {
        require(style in STYLES) { "unknown icon style $style" }
        val pm = context.packageManager
        fun apply(components: List<ComponentName>, on: Boolean) = components.forEach {
            val state = if (on) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            pm.setComponentEnabledSetting(it, state, PackageManager.DONT_KILL_APP)
        }
        // The new pair first, so the app never has no launcher entry.
        apply(aliases(context, style), on = true)
        apply(STYLES.filter { it != style }.flatMap { aliases(context, it) }, on = false)
    }
}
