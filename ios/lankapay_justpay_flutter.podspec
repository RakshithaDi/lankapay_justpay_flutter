#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint lankapay_justpay_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'lankapay_justpay_flutter'
  s.version          = '0.2.14'
  s.summary          = 'Flutter bridge for LankaPay LPTrusted (JustPay) native SDK.'
  s.description      = <<-DESC
Wraps the LPTrusted native SDK behind a MethodChannel (`justpay_sdk/methods`) with
`getDeviceId` and `createIdentityAndSign`. Bank JSON and SDK binaries are supplied by
the integrator; see README.
                       DESC
  s.homepage         = 'https://github.com/ideahub/lankapay_justpay_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'RakshithaDi' => 'rakshithadilshan1@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # MID-style: LPTrustedSDK.xcframework under ios/ or ios/Runner/ (Runner → Embed & Sign).
  # -framework LPTrustedSDK requires -F on each xcframework *slice* (…/ios-arm64, …/simulator);
  # the .xcframework root alone does not satisfy the linker for the plugin pod target.
  fsp_slices = [
    '$(inherited)',
    '"${PODS_ROOT}/.."',
    '"${PODS_ROOT}/../Runner"',
    '"${PODS_ROOT}/../LPTrustedSDK.xcframework/ios-arm64"',
    '"${PODS_ROOT}/../LPTrustedSDK.xcframework/ios-arm64_x86_64-simulator"',
    '"${PODS_ROOT}/../LPTrustedSDK.xcframework/ios-arm64-simulator"',
    '"${PODS_ROOT}/../Runner/LPTrustedSDK.xcframework/ios-arm64"',
    '"${PODS_ROOT}/../Runner/LPTrustedSDK.xcframework/ios-arm64_x86_64-simulator"',
    '"${PODS_ROOT}/../Runner/LPTrustedSDK.xcframework/ios-arm64-simulator"'
  ].join(' ')
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'FRAMEWORK_SEARCH_PATHS' => fsp_slices,
    'OTHER_LDFLAGS' => '$(inherited) -framework LPTrustedSDK',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.swift_version = '5.0'
end
