LPTrustedSDK_Vendored (recommended for Flutter + this plugin)

Why:
  The lankapay_justpay_flutter pod is a separate CocoaPods product. Linking
  LPTrustedSDK only on the Runner app target is not enough — the plugin target
  must see the framework too. A tiny local pod with vendored_frameworks lets
  CocoaPods link and embed consistently (and avoids manual Runner embed cycles).

Layout in YOUR app:

  ios/
    LPTrustedSDK.xcframework          ← from bank / LankaPay
    LPTrustedSDK_Vendored/
      LPTrustedSDK_Vendored.podspec   ← copy from doc/LPTrustedSDK_Vendored/
    Podfile

Podfile (inside target 'Runner' do, before flutter_install_all_ios_pods):

  pod 'LPTrustedSDK_Vendored', :path => 'LPTrustedSDK_Vendored'

Do NOT also add LPTrustedSDK to Runner's manual "Embed Frameworks" if that
creates a cycle with [CP] Embed Pods Frameworks — let this pod own embed/link.

Then: cd ios && pod install --repo-update
