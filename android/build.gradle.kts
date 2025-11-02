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
    // Only redirect build directory for the local "app" project
    // Plugin projects from pub cache should keep their default build directories
    // This prevents conflicts with the Java language server
    val isLocalProject = project.projectDir.path.startsWith(rootProject.projectDir.path)
    val isAppProject = project.name == "app"
    
    if (isAppProject && isLocalProject) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
    // Ensure plugin projects from pub cache are NOT redirected
    // They should use their default build directories in the pub cache
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
