# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'TrinhsGroup' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TrinhsGroup
  pod 'Kingfisher'
  pod 'SwiftyJSON'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Firestore'
  pod 'Stripe'
  pod 'StripePaymentSheet'
  pod 'lottie-ios'
  pod 'netfox'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
      if target.name == 'BoringSSL-GRPC'
        target.source_build_phase.files.each do |file|
          if file.settings && file.settings['COMPILER_FLAGS']
            flags = file.settings['COMPILER_FLAGS'].split
            flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
            file.settings['COMPILER_FLAGS'] = flags.join(' ')
          end
        end
      end
    end
  end
end
