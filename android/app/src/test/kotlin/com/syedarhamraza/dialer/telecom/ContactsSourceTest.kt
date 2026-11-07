package com.syedarhamraza.dialer.telecom

import android.provider.ContactsContract.CommonDataKinds.Phone
import org.junit.Assert.assertEquals
import org.junit.Test

class ContactsSourceTest {
    @Test
    fun phoneTypesUseFlutterContactsLabelNames() {
        assertEquals("mobile", ContactsSource.phoneLabel(Phone.TYPE_MOBILE))
        assertEquals("workMobile", ContactsSource.phoneLabel(Phone.TYPE_WORK_MOBILE))
        assertEquals("homeFax", ContactsSource.phoneLabel(Phone.TYPE_FAX_HOME))
        assertEquals("custom", ContactsSource.phoneLabel(Phone.TYPE_CUSTOM))
        assertEquals("custom", ContactsSource.phoneLabel(null))
    }
}
