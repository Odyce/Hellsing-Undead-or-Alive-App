allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Many Flutter plugins (jni_flutter, file_picker, image_picker, url_launcher, etc.) reference
// flutter.compileSdkVersion / flutter.ndkVersion in their build.gradle files.
// In AGP 8+, these are lazy Properties — assigning null throws at execution time.
// The flutter extension only exists in :app, so we expose all FlutterExtension values
// to every sub-project here, before their build scripts are evaluated.
allprojects {
    beforeEvaluate {
        extra["flutter"] = mapOf(
            "compileSdkVersion" to 36,
            "minSdkVersion" to 24,
            "targetSdkVersion" to 36,
            "ndkVersion" to "28.2.13676358"
        )
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

// NOTE: We intentionally do NOT redirect build directories for plugin sub-projects.
// In AGP 8+, setting buildDirectory on third-party library sub-projects (jni, jni_flutter,
// file_picker, etc.) breaks the lazy provider chain of their JavaCompile tasks, causing
// "Cannot query the value of this provider because it has no value available".
//
// HOWEVER, the :app module MUST follow the redirected root build dir, otherwise its APK
// lands in android/app/build/ while `flutter build apk` looks for it under
// <project_root>/build/app/outputs/. :app uses KGP + the Flutter plugin (not a Java-only
// library), so redirecting its build dir is safe.
subprojects {
    if (name == "app") {
        layout.buildDirectory.set(newBuildDir.dir("app"))
    }
}

// Force all plugin library sub-projects to compileSdk 36.
// android-35/android.jar is missing on this system; android-36 is installed.
// This avoids patching individual pub cache files (which get wiped by flutter pub get).
// Both evaluationDependsOn and afterEvaluate must be in the same block to avoid
// "Cannot run afterEvaluate when the project is already evaluated" when :app is
// evaluated eagerly by the evaluationDependsOn dependency.
subprojects {
    project.evaluationDependsOn(":app")
    val applyCompileSdk = Action<Project> {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.compileSdkVersion(36)
    }
    if (state.executed) {
        applyCompileSdk.execute(this)
    } else {
        afterEvaluate(applyCompileSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
