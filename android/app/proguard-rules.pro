# Added to Flutter's and the plugins' own R8 rules. Keep rules stop R8 from shrinking,
# renaming and optimizing what they match, which is what Play's "DEX code optimization"
# score measures, so keep exact classes only, never whole libraries (`.**`).

# Kotlin classes package:jni looks up by name for suspend functions; jni 1.1.1+ ships these
# itself (pkgs/jni/lib/src/kotlin.dart). path_provider_android depends on jni 1.1.0, which
# doesn't. shortcut: delete once pubspec.lock has jni >= 1.1.1.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
