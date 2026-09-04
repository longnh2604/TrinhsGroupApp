platform :ios, '13.0'
project 'TrinhsGroup'

target 'TrinhsGroup' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TrinhsGroup
  # Unpinned, as the feature branch has been building it (Kingfisher 8.9.0). main pinned
  # 7.12 for Swift 5.9 compatibility, but that was against the pre-migration codebase this
  # merge replaces, and KFImage usage here has been tracking 8.x.
  pod 'Kingfisher'
  pod 'SwiftyJSON'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  # FB-7. Both auto-start from FirebaseApp.configure(), so neither needs setup code.
  # Crashlytics needs the dSYM upload build phase; Performance needs nothing but the pod
  # for its automatic _app_start / network traces, and Trace for the custom ones.
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod 'Stripe'
  pod 'StripePaymentSheet'
  pod 'lottie-ios'
  pod 'netfox'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end

    # BoringSSL-GRPC ships compiler flags that arm64-apple-ios rejects. Both spellings
    # have been seen depending on the CocoaPods version, so drop either.
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-G' || flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
end
