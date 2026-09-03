import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.google.services)
}

/**
 * Read-only WooCommerce key, kept out of source control.
 *
 * Set WOO_CONSUMER_KEY / WOO_CONSUMER_SECRET in local.properties or the environment. The
 * key may only read the public catalog — customer, order and voucher data go through
 * /wp-json/trinh-app/v1 authorised by the signed-in user's JWT — but it is still a
 * credential and does not belong in the repository.
 */
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun secret(name: String): String =
    localProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: System.getenv(name)
        ?: ""

/**
 * Release signing material, kept out of source control alongside the keystore itself.
 *
 * Absent for anyone who has not been given the keystore, so the release signingConfig is
 * only wired up when keystore.properties is present — otherwise the module still
 * configures and debug builds still work.
 */
val keystoreProperties = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.trinhskitchen.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.trinhskitchen.app"
        minSdk = 24
        targetSdk = 36
        versionCode = 6
        versionName = "1.0.2"

        buildConfigField("String", "WOO_CONSUMER_KEY", "\"${secret("WOO_CONSUMER_KEY")}\"")
        buildConfigField("String", "WOO_CONSUMER_SECRET", "\"${secret("WOO_CONSUMER_SECRET")}\"")
    }

    signingConfigs {
        create("release") {
            keystoreProperties.getProperty("storeFile")?.let { path ->
                storeFile = file(path)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Only signed where the keystore is available; elsewhere the release build still
            // runs and produces an unsigned bundle.
            if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation(project(":shared"))

    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.ktx)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.navigation)
    implementation(libs.compose.material.icons)
    implementation(libs.coil.compose)
    implementation(libs.coil.network)
    implementation(libs.koin.android)
    implementation(libs.koin.androidx.compose)
    implementation(libs.androidx.lifecycle.viewmodel)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    
    // Firebase
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.firestore)
    implementation(libs.firebase.messaging)
    
    implementation(libs.lottie.compose)

    // Play In-App Review, for the rating prompt after an order
    implementation(libs.play.review)

    // Stripe
    implementation(libs.stripe.android)
    
    debugImplementation(libs.compose.ui.tooling)
}
