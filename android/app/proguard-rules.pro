# Keep Flutter embedding/plugin classes that may be referenced reflectively.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep OneSignal classes used through reflection.
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Keep Kotlin metadata for runtime annotations/reflection.
-keep class kotlin.Metadata { *; }
