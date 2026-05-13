# الملف: android/app/proguard-rules.pro

## قوانين Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

## قوانين Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## حماية الـ Models بتاعتك (عشان الـ JSON يشتغل صح)
# استبدل com.example.student_management_system باسم الـ package بتاعك
-keep class com.example.student_management_system.models.** { *; }

## قوانين عامة لـ Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }


# حل مشكلة Play Store Missing Classes
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# لو لسه معترض ضيف دول كمان
-keep class com.google.android.play.core.** { *; }