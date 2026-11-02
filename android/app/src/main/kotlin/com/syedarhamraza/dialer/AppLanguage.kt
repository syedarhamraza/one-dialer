package com.syedarhamraza.dialer

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import java.util.Locale

/**
 * Settings › Language: "system" or a language tag. On Android 13+ it is Android's own per-app
 * language (the same value its App languages page edits); below, plain SharedPreferences.
 * Never changes the process default locale, so a live call is untouched.
 */
object AppLanguage {
    private const val FILE = "app_language"
    private const val SYSTEM = "system"

    fun get(context: Context): String =
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales.get(0)?.toLanguageTag() ?: SYSTEM
        } else {
            context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString("language", SYSTEM) ?: SYSTEM
        }

    fun set(context: Context, tag: String) {
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales =
                if (tag == SYSTEM) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(tag)
        } else {
            context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putString("language", tag).apply()
        }
    }

    /** [context] with the chosen language's resources, for notifications (Android 13+ applies it itself). */
    fun localized(context: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return context
        val tag = get(context)
        if (tag == SYSTEM) return context
        val config = Configuration(context.resources.configuration).apply { setLocale(Locale.forLanguageTag(tag)) }
        return context.createConfigurationContext(config)
    }
}
