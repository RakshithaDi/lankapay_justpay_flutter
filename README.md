# lankapay_justpay_flutter

**→ Full step-by-step integration (permissions, Gradle, plist, ATS, JSON, verification): [doc/COMPLETE_SETUP_GUIDE.md](doc/COMPLETE_SETUP_GUIDE.md)**

Flutter **MethodChannel** bridge to the LankaPay **LPTrusted** (JustPay) native SDK. It exposes:

- `getDeviceId()` — LPTrusted device identifier  
- `createIdentityAndSign({ challenge, contentToSign })` — create identity if needed, sign content, validate mobile  

Channel name: **`justpay_sdk/methods`** (package-owned; not tied to a specific app).

This package does **not** include bank REST APIs, onboarding UI, or LankaPay proprietary binaries unless your distribution model explicitly adds them. Confirm redistribution rights for `.aar` / `.xcframework` with LankaPay and your legal team before publishing a build that vendors those files.

## Prerequisites

- Completed (or in-progress) JustPay / MID onboarding with your **acquiring bank**  
- Flutter SDK compatible with `pubspec.yaml`  
- **Android:** min SDK as required by your app (plugin `minSdk` is 24)  
- **iOS:** deployment target **13.0+** (MID); disable Bitcode per MID  
- From the bank / LankaPay kit: **`justpay.json`**, **`mnv.json`**, **`LPTrustedSDK.aar`** (Android), **`LPTrustedSDK.xcframework`** (iOS)  

## Installation

```yaml
dependencies:
  lankapay_justpay_flutter: ^0.2.3
```

Path / git:

```yaml
dependencies:
  lankapay_justpay_flutter:
    path: ../lankapay_justpay_flutter
```

Then:

```bash
flutter pub get
cd ios && pod install && cd ..
```

## Android configuration

1. **SDK binary**  
   Copy `LPTrustedSDK.aar` to **`android/app/libs/LPTrustedSDK.aar`**.  

2. **App `build.gradle` / `build.gradle.kts`**  
   Ensure the host application depends on the AAR (Gradle must see it at **app** level for packaging):

   ```kotlin
   dependencies {
       implementation(files("libs/LPTrustedSDK.aar"))
   }
   ```

   The plugin uses **`compileOnly`** against the same path (`android/app/libs/LPTrustedSDK.aar`) so it can compile against LPTrusted APIs; **your app must still `implementation` the AAR** so classes are packaged in the APK.

3. **MID dependencies**  
   The plugin already depends on **OkHttp 4.9.3** and **json-simple 1.1.1** (`transitive = false`). You may keep the same lines in the app if your MID or other code requires them explicitly.

4. **JSON config**  
   Place **`justpay.json`** and **`mnv.json`** under **`android/app/src/main/res/raw/`** with resource names **`justpay`** and **`mnv`** (files `justpay.json` and `mnv.json`). The bridge validates required keys before calling the SDK (same checks as typical native LPTrusted integration).

5. **Manifest & network**  
   - `INTERNET` permission  
   - `android:networkSecurityConfig` referencing `res/xml/network_security_config.xml` with MID **cleartext / certificate** rules for the four hosts specified in your MID (obtain exact hostnames from the official MID or your bank; do not commit secrets).  

6. **Package name**  
   The `package` field inside `justpay.json` must match the app **`applicationId`** (watch product flavors and suffixes).  

7. **Release / R8**  
   The plugin ships **`consumer-rules.pro`** with a keep rule for `com.lankapay.justpay.**`. Replace or extend with rules LankaPay supplies. Test release builds on device.

## iOS configuration

1. **SDK binary**  
   Copy **`LPTrustedSDK.xcframework`** into your Flutter app under:

   **`ios/JustPaySDK/LPTrustedSDK.xcframework`**

   (sibling folder to `Pods`, as referenced by the plugin podspec’s `FRAMEWORK_SEARCH_PATHS`.)

2. **Embed & Sign**  
   Per MID §7.1.1: add the xcframework to the **Runner** target in Xcode if required by your setup, and ensure it is **Embed & Sign** where the MID dictates.

3. **JSON config**  
   Add **`justpay.json`** and **`mnv.json`** to the **Runner** target → **Copy Bundle Resources** (filenames `justpay.json` and `mnv.json`).

4. **App Transport Security**  
   Add **ATS exception domains** from MID §6.5 (four hosts — use the MID / bank documentation; do not commit confidential endpoints in public repos).

5. **Build settings**  
   - **Bitcode:** No (MID §7.1.2)  
   - **iOS deployment target:** ≥ 13  

6. **Linking**  
   The podspec sets `FRAMEWORK_SEARCH_PATHS` to `"${PODS_ROOT}/../JustPaySDK"` and links `-framework LPTrustedSDK`. If your layout differs, adjust paths or use a `post_install` hook in your `Podfile` to align search paths with your xcframework location.

### Build without LPTrusted (Dart-only / CI)

Swift uses `#if canImport(LPTrustedSDK)` so **analysis** can succeed when the framework is absent, but **release/debug iOS builds** that link the real module still require the xcframework at the documented path.

## Verify setup (quick checklist)

- `flutter pub get` succeeds  
- `cd ios && pod install` succeeds  
- Android: `LPTrustedSDK.aar` exists at `android/app/libs/LPTrustedSDK.aar`  
- Android: `justpay.json` + `mnv.json` exist under `android/app/src/main/res/raw/`  
- Android: `network_security_config.xml` exists and is referenced in `AndroidManifest.xml`  
- iOS: `LPTrustedSDK.xcframework` exists at `ios/JustPaySDK/LPTrustedSDK.xcframework` and is embedded per MID  
- iOS: `justpay.json` + `mnv.json` are in Runner **Copy Bundle Resources**  
- iOS: ATS exception domains are configured per MID  
- `justpay.json` `package` matches Android app `applicationId`  
- `getDeviceId()` returns non-empty on a correctly configured real device  
- `createIdentityAndSign(...)` returns success in your bank sandbox onboarding flow  

## Debug support

- **Logs:**  
  - Android: filter logcat by tag `LankapayJustpay`  
  - iOS: Xcode console lines prefixed with `[LankapayJustpay]`  
  - Dart: debug console logs in debug builds  
- **Debug mocks (optional):**  
  - Use `LankapayJustpayFlutter(enableDebugMocks: true)` to simulate LPTrusted failure responses as success in **debug mode only**.  
  - This helps continue UI flow/testing; backend may still reject dummy `signature`/`mobileReference` if strict validation is enabled.  

## Dart usage

```dart
import 'package:lankapay_justpay_flutter/lankapay_justpay_flutter.dart';

final justPay = LankapayJustpayFlutter();

Future<void> enroll() async {
  final deviceId = await justPay.getDeviceId();
  // Send deviceId to your bank API if required.

  final challenge = '...'; // from your bank JustPay API
  final terms = '...';     // text the user agreed to (per integration guide)

  final result = await justPay.createIdentityAndSign(
    challenge: challenge,
    contentToSign: terms,
  );

  if (result.success) {
    final signature = result.signature;
    final mobileReference = result.mobileReference;
    // POST to your bank register/onboarding API.
  } else {
    // result.message — user-facing error handling
  }
}
```

## Operational & troubleshooting

- **Missing / invalid JSON:** SDK or validation may surface errors (e.g. codes such as **201** / MNV **501** — refer to MID / bank docs).  
- **Wrong applicationId / package:** Identity and signing can fail; align `justpay.json` with the built app id.  
- **ATS / cleartext blocked:** Check `Info.plist` exception domains.  
- **Identity already exists / retry:** Android bridge retries identity creation for selected error codes (300–303, 305) up to two retries after `clearIdentity()`, matching common native LPTrusted retry behavior.  
- **iOS:** If signing fails, confirm **Embed & Sign** and framework search paths for the plugin pod.  

For the full end-to-end integrator checklist (including XML/plist examples and extended troubleshooting), see [`doc/COMPLETE_SETUP_GUIDE.md`](doc/COMPLETE_SETUP_GUIDE.md).

## Distribution variants

| Variant | What you ship | Integrator work |
|--------|----------------|-----------------|
| **BYO SDK (typical public pub.dev)** | Dart + native bridge source only | Add AAR, xcframework, JSON, ATS, network config in the **host app** |
| **Private / licensed bundle** | Above + vendored AAR/xcframework | Legal clearance required; may simplify Gradle/CocoaPods setup |

## Migrating from embedded native JustPay code

If you previously wired LPTrusted yourself in **`MainActivity`** / **`FlutterActivity`** or **`AppDelegate`**:

1. Add `lankapay_justpay_flutter` to `pubspec.yaml`.  
2. Remove your custom JustPay **`MethodChannel`** and duplicate LPTrusted helpers from the host app; use **`LankapayJustpayFlutter`** from this package instead.  
3. Keep Firebase, notifications, and other channels as they are.  
4. This plugin registers **`justpay_sdk/methods`** only; remove any old app-specific JustPay channel name from your code.  
5. Run a full JustPay onboarding regression on Android and iOS.  
