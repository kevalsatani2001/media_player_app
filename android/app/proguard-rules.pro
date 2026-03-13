## Flutter
#-keep class io.flutter.** { *; }
#
## AdMob
#-keep class com.google.android.gms.ads.** { *; }
#-dontwarn com.google.android.gms.ads.**
#
## ExoPlayer
#-keep class com.google.android.exoplayer2.** { *; }
#
## Play Core
#-keep class com.google.android.play.core.** { *; }
#-dontwarn com.google.android.play.core.**
#
## Annotations
#-keepattributes *Annotation*


# ---------------- Flutter ----------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ---------------- AdMob ----------------
-keep public class com.google.android.gms.ads.** { *; }
-keep public class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ---------------- ExoPlayer / Media ----------------
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ---------------- Google Play Core ----------------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ---------------- Firebase (future safe) ----------------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ---------------- Annotations ----------------
-keepattributes *Annotation*

# ---------------- Gson / JSON ----------------
-keepattributes Signature
-keepattributes *Annotation*