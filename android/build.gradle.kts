buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

// Workaround for AGP 8.x+ which strictly requires a namespace for each module.
subprojects {
    val configureNamespace = {
        val android = project.extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension && android.namespace == null) {
            when (project.name) {
                "google_mobile_ads" -> android.namespace = "io.flutter.plugins.googlemobileads"
                "photo_manager" -> android.namespace = "com.fluttercandies.photo_manager"
                "permission_handler_android" -> android.namespace = "com.baseflow.permissionhandler"
                "video_player_android" -> android.namespace = "io.flutter.plugins.videoplayer"
                "shared_preferences_android" -> android.namespace = "io.flutter.plugins.sharedpreferences"
                "share_plus" -> android.namespace = "dev.fluttercommunity.plus.share"
                "path_provider_android" -> android.namespace = "io.flutter.plugins.pathprovider"
                "fluttertoast" -> android.namespace = "com.example.FlutterToast"
            }
        }
    }

    // Try applying now if already added, or when added
    project.plugins.withId("com.android.application") { configureNamespace() }
    project.plugins.withId("com.android.library") { configureNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
