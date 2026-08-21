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

android {
    namespace = "com.trinhskitchen.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.trinhskitchen.app"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        buildConfigField("String", "WOO_CONSUMER_KEY", "\"${secret("WOO_CONSUMER_KEY")}\"")
        buildConfigField("String", "WOO_CONSUMER_SECRET", "\"${secret("WOO_CONSUMER_SECRET")}\"")
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

    // Stripe
    implementation(libs.stripe.android)
    
    debugImplementation(libs.compose.ui.tooling)
}
