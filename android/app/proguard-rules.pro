# google_mlkit_text_recognition ships optional recognizers for Chinese,
# Devanagari, Japanese and Korean script as separate dependencies. This app
# only bundles the Latin recognizer, so R8 can't resolve those classes when
# shrinking — keep the whole mlkit vision package so it stops looking for them.
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
