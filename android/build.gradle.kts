// الملف: android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    // استخدمنا الإصدارات اللي الـ Gradle طلبها في الرسايل اللي فاتت بالظبط
    id("com.android.application") version "8.9.1" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}