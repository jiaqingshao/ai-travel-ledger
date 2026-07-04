# Flutter / Supabase ProGuard rules

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Gson (Supabase 用)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Kotlin reflection
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-keep class kotlinx.coroutines.** { *; }

# Hive
-keep class * extends androidx.lifecycle.ViewModel { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }

# 通用：保留所有 enum (Flutter 包常用)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 移除日志（Release 优化）
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Google Play Core (R8 警告处理 - 我们不用 Split Install)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**