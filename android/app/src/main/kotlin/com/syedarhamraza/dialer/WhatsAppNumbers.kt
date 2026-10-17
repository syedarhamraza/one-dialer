package com.syedarhamraza.dialer

/** Exact matching only: suffix matching can call a different person's number. */
object WhatsAppNumbers {
    fun clean(value: String): String? {
        val compact = value.replace(Regex("[\\s().-]"), "")
        return compact.takeIf { it.matches(Regex("\\+?[0-9]{3,15}")) }
    }

    fun international(value: String): String? = clean(value)?.takeIf {
        it.matches(Regex("\\+[1-9][0-9]{6,14}"))
    }

    fun matchesAccount(account: String?, aliases: Set<String>): Boolean {
        // WhatsApp DATA1 uses an international phone number, often with a JID suffix.
        val digits = account?.removeSuffix("@s.whatsapp.net") ?: return false
        if (!digits.matches(Regex("[1-9][0-9]{6,14}"))) return false
        return aliases.any { international(it)?.removePrefix("+") == digits }
    }
}
