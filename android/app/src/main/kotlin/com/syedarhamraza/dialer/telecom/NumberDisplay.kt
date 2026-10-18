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
        private val cache = HashMap<String, NumberDisplay>()

        fun of(context: Context, number: String?): NumberDisplay? {
            if (number.isNullOrBlank()) return null
            return cache.getOrPut(number) { compute(homeRegion(context), number) }
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

        private fun homeRegion(context: Context): String {
            val telephony = context.getSystemService(TelephonyManager::class.java)
            return listOfNotNull(telephony?.simCountryIso, telephony?.networkCountryIso, Locale.getDefault().country)
                .firstOrNull { it.isNotBlank() }?.uppercase(Locale.ROOT) ?: "ZZ"
        }
    }
}
