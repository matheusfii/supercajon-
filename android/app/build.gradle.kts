import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val releaseSigningConfigured = keyPropertiesFile.exists()
if (releaseSigningConfigured) {
    keyPropertiesFile.inputStream().use(keyProperties::load)
}

android {
    namespace = "supercajon.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "supercajon.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.register("validateReleaseConfiguration") {
    doLast {
        if (!releaseSigningConfigured) {
            throw GradleException(
                "Release signing is not configured. Copy android/key.properties.example " +
                    "to android/key.properties and provide the upload-key credentials."
            )
        }

        val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missingSigningKeys = requiredSigningKeys.filter {
            keyProperties.getProperty(it).isNullOrBlank() ||
                keyProperties.getProperty(it) == "CHANGE_ME"
        }
        if (missingSigningKeys.isNotEmpty()) {
            throw GradleException(
                "Missing Android signing values: ${missingSigningKeys.joinToString()}."
            )
        }
        if (!rootProject.file(keyProperties.getProperty("storeFile")).exists()) {
            throw GradleException("The configured Android upload keystore does not exist.")
        }

        val legalFiles = listOf(
            rootProject.file("../lib/config/legal_config.dart"),
            rootProject.file("../docs/privacy-policy.html"),
            rootProject.file("../docs/terms-of-use.html"),
        )
        if (legalFiles.any { !it.exists() || it.readText().contains("PENDENTE_") }) {
            throw GradleException(
                "Legal information is incomplete in LegalConfig, privacy policy, or terms."
            )
        }
        val legalConfigText = legalFiles.first().readText()
        val httpsLegalUrl = Regex(
            "static\\s+const\\s+(privacyPolicyUrl|termsOfUseUrl)\\s*=\\s*'https://[^']+';"
        )
        if (httpsLegalUrl.findAll(legalConfigText).count() != 2) {
            throw GradleException("Privacy policy and terms URLs must use HTTPS.")
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn("validateReleaseConfiguration")
}
