import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

subprojects {
    if (name == "flutter_exif_plugin") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                namespace = "com.gibabertin.geopic.flutter_exif_plugin"
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = JavaVersion.VERSION_11.toString()
        }
        tasks.register("sanitizeExifPluginManifest") {
            val manifestFile = file("src/main/AndroidManifest.xml")
            inputs.file(manifestFile)
            outputs.file(manifestFile)
            doLast {
                if (!manifestFile.exists()) {
                    return@doLast
                }
                val original = manifestFile.readText()
                val sanitized = original.replace(
                    Regex("package\\s*=\\s*\"[^\"]+\""),
                    "",
                )
                if (sanitized != original) {
                    manifestFile.writeText(sanitized)
                }
            }
        }
        tasks.matching { it.name == "preBuild" }.configureEach {
            dependsOn("sanitizeExifPluginManifest")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
