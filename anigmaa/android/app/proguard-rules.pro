# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google OAuth
-keep class com.google.** { *; }

# Payment Gateway (Midtrans)
-keep class com.midtrans.** { *; }

# Network libraries
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class javax.annotation.** { *; }
-keep class kotlin.** { *; }

# JSON parsing
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { *; }

# Keep model classes
-keep class com.anigmaa.app.** { *; }
-keep class com.anigmaa.app.data.model.** { *; }
-keep class com.anigmaa.app.domain.entities.** { *; }
