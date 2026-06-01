# ProGuard rules for the application

# Fix WorkManager crash in release builds due to R8 obfuscating the initialization classes
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-keepclassmembers class androidx.startup.** { *; }
