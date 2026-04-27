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
