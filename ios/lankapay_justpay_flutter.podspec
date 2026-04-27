#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint lankapay_justpay_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'lankapay_justpay_flutter'
  s.version          = '0.2.9'
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

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.dependency 'LPTrustedSDK'

  s.swift_version = '5.0'
end
