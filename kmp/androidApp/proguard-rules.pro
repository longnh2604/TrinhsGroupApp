# R8 rules for the release build.
#
# Most libraries here ship their own rules (kotlinx.serialization, Ktor, Koin, Firebase,
# Stripe, Lottie, Coil). Add a rule only for something R8 breaks, with the reason beside it.

# Keep line numbers in Crashlytics stack traces; the file name is hidden.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
