# Keep app classes
-keep class com.hey.mery.** { *; }

# ONNX Runtime
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Flutter plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# OkHttp (used by http package)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Gson (used by various libraries)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep MethodChannel names
-keep class com.hey.mery.controller.** { *; }
-keep class com.hey.mery.service.** { *; }

# General rules
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
