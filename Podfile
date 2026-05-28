platform :ios, '13.0'
project 'TrinhsGroup.xcodeproj'

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
  pod 'lottie-ios'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end

  # Fix BoringSSL-GRPC '-G' flag incompatibility with arm64-apple-ios
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS']
          flags = flags.split(' ').reject { |f| f == '-G' }.join(' ')
          file.settings['COMPILER_FLAGS'] = flags
        end
      end
    end
  end
end
