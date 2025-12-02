import com.android.build.gradle.AppExtension
import com.android.build.gradle.LibraryExtension

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
    afterEvaluate {
        if (name == "flutter_bluetooth_serial") {
            extensions.findByType(LibraryExtension::class.java)?.let { lib ->
                if (lib.namespace == null) {
                    lib.namespace = "io.github.edufolly.flutterbluetoothserial"
                }
            }
        }

        // Force newer SDK levels so plugins (e.g., flutter_bluetooth_serial, path_provider_android)
        // see android:attr/lStar and comply with their declared compile SDK of 36.
        extensions.findByType(AppExtension::class.java)?.let { app ->
            app.compileSdkVersion(36)
            app.defaultConfig.targetSdkVersion(36)
        }
        extensions.findByType(LibraryExtension::class.java)?.let { lib ->
            lib.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
