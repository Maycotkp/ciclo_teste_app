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

// Alguns plugins (via flutter_plugin_android_lifecycle) exigem compileSdk 36+,
// mas herdam o padrão do Flutter Gradle Plugin (34). Forçamos 36 em todos os
// módulos Android (app e plugins), via afterEvaluate para vencer o valor que
// o próprio script do plugin já define.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let {
                it.compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
