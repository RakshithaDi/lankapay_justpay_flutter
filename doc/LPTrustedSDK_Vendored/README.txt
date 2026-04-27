LPTrustedSDK_Vendored (optional CocoaPods fallback for Flutter + this plugin)

When to use:
  Default integration follows MID: add LPTrustedSDK.xcframework in Xcode
  (Runner → Embed & Sign) and keep the xcframework on disk under ios/ or
  ios/Runner/ so the plugin pod can link (see plugin README section 10).

  Use this tiny path pod only if you still get Framework 'LPTrustedSDK' not
  found for the plugin target, or an embed / thin-binary cycle between manual
  Runner embed and [CP] Embed Pods Frameworks.

Layout in YOUR app (fallback):

  ios/
    LPTrustedSDK.xcframework          ← from bank / LankaPay
    LPTrustedSDK_Vendored/
      LPTrustedSDK_Vendored.podspec   ← copy from doc/LPTrustedSDK_Vendored/
    Podfile

Podfile (inside target 'Runner' do, before flutter_install_all_ios_pods):

  pod 'LPTrustedSDK_Vendored', :path => 'LPTrustedSDK_Vendored'

If you use this pod, avoid duplicating LPTrustedSDK in Runner's manual Embed
Frameworks if that creates a cycle with CocoaPods embed — let the pod own
embed/link, or follow your bank's guidance.

Then: cd ios && pod install --repo-update
