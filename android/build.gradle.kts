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
// Note: evaluationDependsOn(":app") removed to avoid errors when Android SDK is not configured
// This line is optional and only affects build order, not functionality

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
