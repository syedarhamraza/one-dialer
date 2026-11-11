package com.syedarhamraza.dialer.telecom

import android.content.Context
import android.telephony.TelephonyManager
import com.google.i18n.phonenumbers.NumberParseException
import com.google.i18n.phonenumbers.PhoneNumberUtil
import com.google.i18n.phonenumbers.PhoneNumberUtil.PhoneNumberFormat
import java.util.Locale

/** How the call screen shows a number: grouped digits, plus the caller's country (as ColorOS shows a place). */
data class NumberDisplay(val formatted: String?, val location: String?) {
    companion object {
        private const val CACHE_SIZE = 1000

        // Read from the main thread (call snapshots) and background threads (describeNumbers), so
        // it's locked; least recently used numbers go once it's full.
        private val cache = object : LinkedHashMap<String, NumberDisplay>(64, .75f, true) {
            override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, NumberDisplay>?) = size > CACHE_SIZE
        }

        fun of(context: Context, number: String?): NumberDisplay? {
            if (number.isNullOrBlank()) return null
            synchronized(cache) { cache[number] }?.let { return it }
            // Computed outside the lock: parsing is slow and the main thread mustn't wait on a list's worth.
            return compute(homeRegion(context), number).also { synchronized(cache) { cache[number] = it } }
        }

        /** Pure so it can be unit-tested without Android. */
        fun compute(home: String, number: String): NumberDisplay {
            val util = PhoneNumberUtil.getInstance()
            val parsed = try {
                util.parse(number, home)
            } catch (_: NumberParseException) {
                return NumberDisplay(null, null)
            }
            // Short codes and service numbers stay as dialled.
            if (!util.isPossibleNumber(parsed)) return NumberDisplay(null, null)
            val region = util.getRegionCodeForNumber(parsed)
            val foreign = region != null && region != "ZZ" && region != home
            return NumberDisplay(
                formatted = util.format(parsed, if (foreign) PhoneNumberFormat.INTERNATIONAL else PhoneNumberFormat.NATIONAL),
                location = region?.takeIf { it != "ZZ" }?.let { Locale("", it).displayCountry }?.takeIf { it.isNotBlank() },
            )
        }

        /** The keypad's number grouped as it's typed ("0333 333"), like Android's own dialer. */
        fun asYouType(context: Context, number: String): String = asYouType(homeRegion(context), number)

        fun asYouType(home: String, number: String): String {
            val formatter = PhoneNumberUtil.getInstance().getAsYouTypeFormatter(home)
            var out = number
            for (c in number) out = formatter.inputDigit(c)
            return out
        }

        /** Loads the home region's number data off the main thread, so the first typed digit doesn't wait for it. */
        fun preload(context: Context) {
            Thread { asYouType(context, "0") }.start()
        }

        // shortcut: looked up once per process (a call into the phone service); a SIM from another country
        // swapped in while the app runs keeps the old grouping until restart.
        @Volatile private var home: String? = null

        private fun homeRegion(context: Context): String {
            home?.let { return it }
            val telephony = context.getSystemService(TelephonyManager::class.java)
            val sim = telephony?.simCountryIso?.takeIf { it.isNotBlank() }?.uppercase(Locale.ROOT)
            // Only the SIM's country is kept; the fallbacks are asked again until the SIM is ready.
            if (sim != null) return sim.also { home = it }
            return listOfNotNull(telephony?.networkCountryIso, Locale.getDefault().country)
                .firstOrNull { it.isNotBlank() }?.uppercase(Locale.ROOT) ?: "ZZ"
        }
    }
}
