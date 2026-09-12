    buildscript {
        extra["kotlin_version"] = "2.2.20"
    }

    allprojects {
        repositories {
            google()
            mavenCentral()
            maven(url = "https://www.jitpack.io")
            maven(url = "https://maven.zego.im")
        }
    }

    subprojects {
        buildscript {
            repositories {
                mavenCentral()
                google()
            }
        }
        repositories {
            mavenCentral()
            google()
        }
    }

    val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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