# The Flutter ML Kit plugin exposes optional recognizers for these scripts.
# CoSci uses only the bundled Latin recognizer, so the optional classes are
# intentionally absent from the Android application.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
