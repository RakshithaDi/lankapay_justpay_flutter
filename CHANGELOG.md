## 0.2.16

* Docs: remove **`LPTrustedSDK_Vendored`** fallback guidance from setup/troubleshooting and keep iOS integration path focused on direct **`LPTrustedSDK.xcframework`** + CocoaPods flow.
* Docs: update iOS wording to treat **`mnv.json`** as required in bundle/setup/checklists for this integration guide.

## 0.2.15

* Docs: Android **`network_security_config.xml`** and iOS **`NSAppTransportSecurity`** examples include UAT-style MNV hosts **`3lauth.ideabiz.lk`** and **`gsmacnvep.mobitel.lk`** alongside **`mobileauth.ideabiz.lk`**, **`gsmacnv.mobitel.lk`**, and Hutch hosts (**`README.md`**, **`doc/COMPLETE_SETUP_GUIDE.md`**, **`example/README.md`**).

## 0.2.14

* iOS: extend **`FRAMEWORK_SEARCH_PATHS`** with common **`LPTrustedSDK.xcframework`** slice directories (**`ios-arm64`**, **`ios-arm64_x86_64-simulator`**, **`ios-arm64-simulator`**) under both **`ios/`** and **`ios/Runner/`**, so **`lankapay_justpay_flutter`** links **`LPTrustedSDK`** without a host **`Podfile`** `post_install` (the linker needs **`-F`** on each slice that contains **`LPTrustedSDK.framework`**, not only the xcframework root).

## 0.2.13

* iOS: **`mnv.json`** is no longer required in the app bundle. If present, **`dialog`**, **`hutch`**, and **`mobitel`** are still validated before calling the SDK; if absent, the plugin proceeds with **`justpay.json`** only. Android unchanged (**`mnv.json`** still required in **`res/raw`**).

## 0.2.12

* iOS: default integration again matches **MID manual Xcode** flow (add `LPTrustedSDK.xcframework` + **Embed & Sign** on Runner, add `justpay.json` to the app target). Plugin pod restores **`FRAMEWORK_SEARCH_PATHS`** on **`ios/`** and **`ios/Runner/`** plus **`-framework LPTrustedSDK`** so the **plugin** target links without a separate `LPTrustedSDK_Vendored` CocoaPod.
* iOS docs: **`LPTrustedSDK_Vendored`** is documented only as an **optional** fallback if you hit **Framework not found** / **embed cycle** issues with CocoaPods.

## 0.2.11

* iOS: when `getDeviceId` returns empty because the **stub** path is used, log a clear `[LankapayJustpay]` message in Xcode (DEBUG) so it is obvious that `LPTrustedSDK` was not linked at compile time.

## 0.2.10

* iOS: depend on **`LPTrustedSDK_Vendored`** (local pod) instead of a bare `LPTrustedSDK` name, so CocoaPods links/embeds the xcframework for the **plugin pod** as well as Runner (fixes **Framework LPTrustedSDK not found** when only Runner linked the xcframework manually).
* iOS docs: add **`doc/LPTrustedSDK_Vendored/`** template and explain avoiding manual Runner **Embed Frameworks** cycles with **[CP] Embed Pods Frameworks**.
* Example `ios/Podfile`: document the `LPTrustedSDK_Vendored` path pod line.

## 0.2.9

* iOS: fix Swift compile error in `JustPaySdkHandler.deviceId()` by safely unwrapping optional return from `LPTrustedSDKManager.getDeviceId()`.

## 0.2.8

* iOS: remove framework search/linker flag hacks and depend on `LPTrustedSDK` pod directly from plugin podspec.
* iOS docs: switch integration flow from manual xcframework placement to CocoaPods-based `LPTrustedSDK` sourcing.
* Added `doc/LPTrustedSDK.podspec.example` template for private/public pod distribution.

## 0.2.7

* iOS: change LPTrusted framework placement to `ios/LPTrustedSDK.xcframework` (remove `JustPaySDK` subfolder requirement).
* Docs: update root and example setup guides to reflect the new iOS framework path.

## 0.2.6

* Android docs/example: add workaround for LPTrusted AAR duplicate-class conflicts by excluding `commons-io` and `slf4j-api` in host app Gradle.

## 0.2.5

* Android: enable `buildFeatures.buildConfig` so `BuildConfig.DEBUG` resolves when compiling the library with Android Gradle Plugin 8+ (fixes `cannot find symbol: variable BuildConfig` in `JustPayNativeBridge`).
* Android docs/example: add workaround for LPTrusted AAR duplicate-class conflicts by excluding `commons-io` and `slf4j-api` in host app Gradle.

## 0.2.4

* Docs: publish latest README improvements and refresh dependency snippet version.

## 0.2.3

* Docs: expanded README setup guidance and synchronized README/example docs for clearer integrator onboarding.

## 0.2.2

* Debug: added Android/iOS/Dart logs for native flow visibility.
* Debug-only: added `enableDebugMocks` to simulate LPTrusted failure as success to keep debug UI/backend flow moving (dummy signature/mobileReference; backend may still reject).
* Example app UI updated to call `createIdentityAndSign`.

## 0.2.1

* README: remove redundant pub.dev publishing checklist (integrators use this README on pub.dev).

## 0.2.0

* Android plugin Java/Kotlin package and Gradle **namespace** moved from `com.example.lankapay_justpay_flutter` to **`lk.lankapay.justpay_flutter`**.
* Example app Android **`applicationId`** / namespace and iOS **bundle ID** updated to **`lk.lankapay.*`** (align `justpay.json` **`package`** with your real app id).
* **pubspec** / **podspec** metadata: `homepage`, `repository`, `issue_tracker`, author **IdeaHub** & **opensource@ideahub.lk** (GitHub org **ideahub**; adjust if your repo lives elsewhere).

## 0.1.0

* Initial JustPay / LPTrusted bridge: `getDeviceId`, `createIdentityAndSign` on channel `justpay_sdk/methods`.
* Android: `FlutterPlugin` registration, `JustPayNativeBridge` (OkHttp 4.9.3, json-simple), `consumer-rules.pro`, compileOnly AAR from `android/app/libs/LPTrustedSDK.aar`.
* iOS: `JustPaySdkHandler` + podspec iOS 13+ with `JustPaySDK` framework search path; `#if canImport(LPTrustedSDK)` stub when framework absent.
* Integrator README and **doc/COMPLETE_SETUP_GUIDE.md** for JSON placement and MID networking.
* Publish hygiene: MIT **LICENSE**, **.pubignore** (no proprietary SDK in tarball), `doc/` layout for pub.dev.

## 0.0.1

* Placeholder scaffold (platform version demo).
