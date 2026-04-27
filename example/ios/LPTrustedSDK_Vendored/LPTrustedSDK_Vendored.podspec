# Example copy — same as doc/LPTrustedSDK_Vendored/LPTrustedSDK_Vendored.podspec
# Place bank LPTrustedSDK.xcframework at example/ios/LPTrustedSDK.xcframework for local builds.

Pod::Spec.new do |s|
  s.name             = 'LPTrustedSDK_Vendored'
  s.version          = '1.0.0'
  s.summary          = 'Vendored wrapper for LPTrustedSDK.xcframework'
  s.description      = 'Wraps LPTrustedSDK.xcframework for CocoaPods (Flutter plugin compatible).'
  s.homepage         = 'https://github.com/ideahub/lankapay_justpay_flutter'
  s.license          = { :type => 'Commercial', :text => 'Proprietary — LPTrustedSDK is supplied by the integrator.' }
  s.author           = { 'Integrator' => 'integrator@example.com' }
  s.platform         = :ios, '13.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = '../LPTrustedSDK.xcframework'
end
