###############################################################################
# Flutter defaults
###############################################################################

# Keep all Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.FlutterInjector { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }

# Keep generated PluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

###############################################################################
# sqflite
###############################################################################
-keep class com.tekartik.sqflite.** { *; }

###############################################################################
# flutter_local_notifications
###############################################################################
-keep class com.dexterous.** { *; }

###############################################################################
# permission_handler
###############################################################################
-keep class com.baseflow.permissionhandler.** { *; }

###############################################################################
# timezone
###############################################################################
-keep class org.joda.time.** { *; }
-keep class tz.** { *; }

###############################################################################
# General (safe defaults)
###############################################################################

# Keep all annotations
-keepattributes *Annotation*
# Ignore warnings about Play Core missing (we’re not using deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
