# Optional fallback: copy this folder to ios/LPTrustedSDK_Vendored/ and keep
# LPTrustedSDK.xcframework at ios/LPTrustedSDK.xcframework (sibling).
# Default integration is MID manual Xcode + xcframework on disk under ios/ or ios/Runner/
# (see plugin README). Use this pod if Framework not found / embed cycles persist.
#
# In ios/Podfile inside target 'Runner':
#   pod 'LPTrustedSDK_Vendored', :path => 'LPTrustedSDK_Vendored'

Pod::Spec.new do |s|
  s.name             = 'LPTrustedSDK_Vendored'
  s.version          = '1.0.0'
  s.summary          = 'Vendored wrapper for LPTrustedSDK.xcframework'
  s.description      = <<-DESC
    Wraps the bank-supplied LPTrustedSDK.xcframework so CocoaPods links and embeds it
    for all dependent targets, including the lankapay_justpay_flutter plugin pod.
    Avoids linking LPTrustedSDK only on Runner while the plugin target still needs the framework.
  DESC
  s.homepage         = 'https://github.com/ideahub/lankapay_justpay_flutter'
  s.license          = { :type => 'Commercial', :text => 'Proprietary — LPTrustedSDK is supplied by the integrator.' }
  s.author           = { 'Integrator' => 'integrator@example.com' }
  s.platform         = :ios, '13.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = '../LPTrustedSDK.xcframework'
end
