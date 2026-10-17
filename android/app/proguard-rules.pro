# shared_preferences_android 2.5 calls its Kotlin `suspend` API from Dart over JNI
# (package:jni). R8 sees no Java callers and strips or renames those classes, so every
# DialerPrefs read and write fails, but only in release builds. Keep the plugin, the
# JNI bridge, and the coroutine/DataStore types those calls pass through.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class androidx.datastore.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$* { *; }
-keep class kotlin.ResultKt { *; }
