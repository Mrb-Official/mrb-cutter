# Permission Handler ko safe rakhne ke liye
-keep class com.baseflow.permissionhandler.** { *; }
-keep interface com.baseflow.permissionhandler.** { *; }

# FFmpeg Kit ko safe rakhne ke liye (video processing ke time crash na ho)
-keep class com.arthenica.ffmpegkit.** { *; }

# Baaki sabhi native Flutter plugins ko bachane ke liye
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }