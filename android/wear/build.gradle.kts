import org.gradle.api.GradleException
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

fun hasGoogleServicesConfig(): Boolean =
    listOf(
        "google-services.json",
        "src/debug/google-services.json",
        "src/release/google-services.json",
    ).any { path -> file(path).exists() }

val hasFirebaseConfig = hasGoogleServicesConfig()

if (hasFirebaseConfig) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

val releaseSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}
val releaseSigningPropertyNames = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val hasReleaseSigningConfig = releaseSigningPropertyNames.all { name ->
    !releaseSigningProperties.getProperty(name).isNullOrBlank()
}

fun releaseSigningProperty(name: String): String =
    releaseSigningProperties.getProperty(name)
        ?: throw GradleException("Missing '$name' in android/key.properties.")

fun releaseKeystoreFile() = rootProject.file(releaseSigningProperty("storeFile"))

fun requireReleaseSigningConfig() {
    if (!hasReleaseSigningConfig) {
        throw GradleException(
            "Missing Android release signing config. Create android/key.properties " +
                "with storeFile, storePassword, keyAlias, and keyPassword.",
        )
    }
    if (!releaseKeystoreFile().isFile) {
        throw GradleException(
            "Missing Android release keystore at ${releaseKeystoreFile().path}.",
        )
    }
}

android {
    namespace = "kr.sjh.runlini.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "kr.sjh.runlini"
        minSdk = 30
        targetSdk = 36
        versionCode = 36010001
        versionName = "1.0.0"
    }

    buildFeatures {
        buildConfig = true
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                storeFile = releaseKeystoreFile()
                storePassword = releaseSigningProperty("storePassword")
                keyAlias = releaseSigningProperty("keyAlias")
                keyPassword = releaseSigningProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.matching { task ->
    task.name in setOf("assembleRelease", "bundleRelease", "packageRelease")
}.configureEach {
    doFirst {
        requireReleaseSigningConfig()
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.02.01")

    implementation(composeBom)
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.health:health-services-client:1.1.0-rc01")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.10.0")
    implementation("androidx.wear.compose:compose-foundation:1.5.6")
    implementation("androidx.wear.compose:compose-material3:1.5.6")
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
    if (hasFirebaseConfig) {
        implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
        implementation("com.google.firebase:firebase-crashlytics")
    }
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")

    debugImplementation("androidx.compose.ui:ui-tooling")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250517")
}
