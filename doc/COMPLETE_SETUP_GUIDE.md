# Complete setup guide: `lankapay_justpay_flutter`

This document is the **full, ordered checklist** for integrating the plugin. Follow it top to bottom the first time you integrate. Example XML in the Android and iOS sections matches common MID patterns for MNV cleartext hosts; always confirm values against **your** official MID.

**Related files in this repo**

| Item | Location |
|------|----------|
| Short overview | [README.md](../README.md) |
| Example app | [example/](../example/) |
| Method channel name | `justpay_sdk/methods` |

---

## Table of contents

1. [Before you write any code](#1-before-you-write-any-code)
2. [Update your Flutter project](#2-update-your-flutter-project)
3. [Add the Dart dependency](#3-add-the-dart-dependency)
4. [Android — LPTrusted AAR](#4-android--lptrusted-aar)
5. [Android — Gradle (app module)](#5-android--gradle-app-module)
6. [Android — Config JSON in `res/raw`](#6-android--config-json-in-resraw)
7. [Android — Permissions (`AndroidManifest.xml`)](#7-android--permissions-androidmanifestxml)
8. [Android — Network security (cleartext / MNV)](#8-android--network-security-cleartext--mnv)
9. [Android — ProGuard / R8 (release)](#9-android--proguard--r8-release)
10. [iOS — LPTrusted xcframework layout](#10-ios--lptrusted-xcframework-layout)
11. [iOS — CocoaPods](#11-ios--cocoapods)
12. [iOS — Bundle JSON](#12-ios--bundle-json)
13. [iOS — App Transport Security (ATS)](#13-ios--app-transport-security-ats)
14. [iOS — Xcode build settings](#14-ios--xcode-build-settings)
15. [iOS — Embed & Sign the framework](#15-ios--embed--sign-the-framework)
16. [Dart — Usage in your app](#16-dart--usage-in-your-app)
17. [Config JSON — Required keys (reference)](#17-config-json--required-keys-reference)
18. [Verify the integration](#18-verify-the-integration)
19. [Migrating from embedded native JustPay code](#19-migrating-from-embedded-native-justpay-code)
20. [Troubleshooting](#20-troubleshooting)

---

## 1. Before you write any code

Obtain from your **bank / LankaPay onboarding** (not from this open-source repo):

| Asset | Android | iOS |
|--------|---------|-----|
| `justpay.json` | Place in `res/raw` | Add to Runner bundle |
| `mnv.json` | Place in `res/raw` | Add to Runner bundle |
| Native SDK | `LPTrustedSDK.aar` | `LPTrustedSDK.xcframework` |


---

## 2. Update your Flutter project

1. Use a **stable Flutter** channel and a Dart SDK compatible with the plugin’s `pubspec.yaml` (`environment.sdk`).
2. From your app root:

   ```bash
   flutter upgrade
   flutter doctor -v
   ```

Fix any **Android SDK / Xcode / CocoaPods** issues `flutter doctor` reports before continuing.

---

## 3. Add the Dart dependency

In your app’s **`pubspec.yaml`**:

```yaml
dependencies:
  flutter:
    sdk: flutter
  lankapay_justpay_flutter: ^0.2.7   # or path: / git: for your team
```

Then:

```bash
flutter pub get
```

**Import:**

```dart
import 'package:lankapay_justpay_flutter/lankapay_justpay_flutter.dart';
```

---

## 4. Android — LPTrusted AAR

1. Create the folder **`android/app/libs/`** if it does not exist.
2. Copy the bank’s file **`LPTrustedSDK.aar`** into:

   **`android/app/libs/LPTrustedSDK.aar`**

   Use **exactly** this filename unless you change every Gradle reference yourself.

3. The plugin’s Android module uses **`compileOnly`** against:

   **`$rootProjectDir/app/libs/LPTrustedSDK.aar`**

   (same path relative to your Flutter app’s **`android/`** folder). If this file is missing, Android Gradle fails with an explicit error from the plugin — that is expected until the AAR is present.

---

## 5. Android — Gradle (app module)

Edit **`android/app/build.gradle`** or **`android/app/build.gradle.kts`**.

### Kotlin DSL (`build.gradle.kts`) — recommended pattern

Add a **`dependencies { }`** block (or merge into your existing one):

```kotlin
dependencies {
    // Required: packages LPTrusted into the APK. The plugin only compileOnly-compiles against it.
    implementation(files("libs/LPTrustedSDK.aar"))

    // MID-aligned versions (OkHttp 4.9.3, json-simple non-transitive).
    // The plugin also declares OkHttp + json-simple; duplicating here is optional but explicit.
    implementation("com.squareup.okhttp3:okhttp:4.9.3")
    implementation("com.googlecode.json-simple:json-simple:1.1.1") {
        isTransitive = false
    }
}
```

### Groovy (`build.gradle`)

```groovy
dependencies {
    implementation files('libs/LPTrustedSDK.aar')
    implementation 'com.squareup.okhttp3:okhttp:4.9.3'
    implementation('com.googlecode.json-simple:json-simple:1.1.1') {
        transitive = false
    }
}
```

If your build fails with duplicate classes from `org.apache.commons.io.*` or `org.slf4j.*`, add this in the app module:

```kotlin
configurations.configureEach {
    exclude(group = "commons-io", module = "commons-io")
    exclude(group = "org.slf4j", module = "slf4j-api")
}
```

```groovy
configurations.all {
    exclude group: "commons-io", module: "commons-io"
    exclude group: "org.slf4j", module: "slf4j-api"
}
```

**`applicationId` / flavors:** The value of **`package`** inside `justpay.json` must match the **built app’s** `applicationId` (including flavor suffixes such as `.dev`). If they differ, identity and signing will fail.

---

## 6. Android — Config JSON in `res/raw`

1. Copy your bank’s files to:

   - **`android/app/src/main/res/raw/justpay.json`**
   - **`android/app/src/main/res/raw/mnv.json`**

2. **Resource names** are the filenames **without** extension: `justpay` and `mnv`. Do not rename to `justpay_config.json` unless you also change native loading logic (this plugin expects those two names).

3. The plugin validates **required keys** before calling the SDK (see [section 17](#17-config-json--required-keys-reference)).

---

## 7. Android — Permissions (`AndroidManifest.xml`)

JustPay / LPTrusted needs **network access**. Declaring **network state** is optional but useful for connectivity-aware behavior.

### Minimum recommended for JustPay networking

Inside **`<manifest>`** (not inside `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Other permissions

Typical banking apps also declare permissions for notifications, camera, biometric, and so on. Those are **not required by this plugin** unless **your** app uses those features. For **JustPay-only** networking, **`INTERNET`** (+ optionally **`ACCESS_NETWORK_STATE`**) is the core set.

**Optional (only if your MID or bank doc says so):** Some integrations mention telephony. Follow **your** MID if it requires `READ_PHONE_STATE` or similar.

### Application attribute for network security

On **`<application>`**, point to your XML config (see next section). Example:

```xml
<application
    android:name="${applicationName}"
    android:label="your_app_name"
    android:icon="@mipmap/ic_launcher"
    android:networkSecurityConfig="@xml/network_security_config">
    <!-- activities, meta-data, etc. -->
</application>
```

---

## 8. Android — Network security (cleartext / MNV)

Mobile network validation (MNV) often uses **HTTP** to specific operator endpoints. Android 9+ blocks cleartext unless you allow it per domain.

1. Create **`android/app/src/main/res/xml/network_security_config.xml`**.

2. Example content (replace domains with those from **your** MID if they differ):

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">mobileauth.ideabiz.lk</domain>
        <domain includeSubdomains="true">gsmacnv.mobitel.lk</domain>
        <domain includeSubdomains="true">apihub.hutch.lk</domain>
        <domain includeSubdomains="true">heapihub.hutch.lk</domain>
    </domain-config>
</network-security-config>
```

3. Ensure **`AndroidManifest.xml`** references it (see [section 7](#7-android--permissions-androidmanifestxml)).

**Important:** If your bank’s MID lists **different** hosts for sandbox/production, replace these domains accordingly. The block above is an **example**, not a substitute for your MID.

---

## 9. Android — ProGuard / R8 (release)

1. This plugin publishes **`consumer-rules.pro`** with:

   ```pro
   -keep class com.lankapay.justpay.** { *; }
   ```

2. If LankaPay or your bank supplies **additional** ProGuard rules, merge them into your app’s **`proguard-rules.pro`** (or the rules file your release build uses).

3. Always run a **release** build on a **real device** and exercise **JustPay onboarding** before store submission.

---

## 10. iOS — LPTrusted xcframework layout

1. Under your Flutter app’s **`ios/`** folder, use this layout (matches this plugin’s **podspec** `FRAMEWORK_SEARCH_PATHS`):

   ```
   ios/
     LPTrustedSDK.xcframework   ← entire xcframework bundle here
     Podfile
     Runner/
     ...
   ```

2. Copy the bank’s **`LPTrustedSDK.xcframework`** into **`ios/`** so the path is:

   **`ios/LPTrustedSDK.xcframework`**

---

## 11. iOS — CocoaPods

1. Open a terminal at **`your_app/ios/`**.

2. Run:

   ```bash
   pod install
   ```

3. If you change the plugin version or iOS native deps, run again:

   ```bash
   pod install --repo-update
   ```

4. Open **`Runner.xcworkspace`** in Xcode (not **`Runner.xcodeproj`** alone).

**Podfile `platform`:** Use at least **iOS 13.0** (MID). Your team may standardize on a higher minimum; that is fine as long as it meets MID requirements.

---

## 12. iOS — Bundle JSON

1. In Xcode, select **`justpay.json`** and **`mnv.json`**.
2. In the **File inspector**, under **Target Membership**, enable **Runner**.
3. Confirm both appear under **Build Phases → Copy Bundle Resources**.

Filenames on disk should be **`justpay.json`** and **`mnv.json`** so `Bundle.main.url(forResource:withExtension:)` finds them.

---

## 13. iOS — App Transport Security (ATS)

iOS blocks insecure HTTP unless you declare exceptions. Add **`NSAppTransportSecurity`** for the **same operator hosts** you allow in Android cleartext (example below; align with your MID):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>mobileauth.ideabiz.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>gsmacnv.mobitel.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>apihub.hutch.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>heapihub.hutch.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**How to add in Xcode:** Open **Runner → Info.plist** as source code, or use **Information Property List** editor: add **App Transport Security Settings → Exception Domains** and mirror the keys above.

Again: **confirm hosts with your MID** for non-production environments.

---

## 14. iOS — Xcode build settings

Per MID:

| Setting | Value |
|---------|--------|
| **iOS Deployment Target** | ≥ **13.0** (MID minimum; your app may use a higher floor) |
| **Enable Bitcode** | **No** (MID) |

In Xcode: **Runner target → Build Settings → search “Bitcode” → Enable Bitcode → No**.

---

## 15. iOS — Embed & Sign the framework

1. In Xcode, select the **Runner** target → **General → Frameworks, Libraries, and Embedded Content** (or **Build Phases → Embed Frameworks**).
2. Add **`LPTrustedSDK.xcframework`**.
3. Set embed option to **Embed & Sign** if that is what your MID / bank instructions require.

The plugin podspec adds **search paths** and **`-framework LPTrustedSDK`** for the **plugin** target. If you still see link errors, confirm the xcframework path, run **`pod install`**, and compare **Frameworks, Libraries, and Embedded Content** with a **working native sample** from your bank or MID package if one was provided.

---

## 16. Dart — Usage in your app

```dart
final justPay = LankapayJustpayFlutter();

// 1) Optional: device id for your backend
final deviceId = await justPay.getDeviceId();

// 2) challenge from your bank API; contentToSign = e.g. terms text user agreed to
final result = await justPay.createIdentityAndSign(
  challenge: challengeFromApi,
  contentToSign: termsPlainText,
);

if (result.success) {
  final signature = result.signature;
  final mobileReference = result.mobileReference;
  // Send signature + mobileReference to your bank API per integration guide.
} else {
  // Show result.message to the user or log for support.
}
```

**Threading:** Native callbacks complete on the platform main thread; the plugin returns a `Future` to Dart as usual.

---

## 17. Config JSON — Required keys (reference)

These are validated **before** the SDK runs (mirroring typical native LPTrusted integration checks).

### `justpay.json` (string values, non-empty after trim)

| Key |
|-----|
| `url` |
| `package` |
| `justpay_code` |
| `key_encipher` |
| `key_signer` |
| `justpay_cert` |
| `issuer` |

### `mnv.json`

| Key |
|-----|
| `dialog` |
| `hutch` |
| `mobitel` |

If any are missing, you get a structured error **`message`** in the Dart result (Android) or the same shape from iOS.

---

## 18. Verify the integration

Use this checklist on a **physical device** when possible (MNV often depends on real carrier data).

- [ ] `flutter pub get` succeeds.
- [ ] `cd ios && pod install` succeeds.
- [ ] Android: **`LPTrustedSDK.aar`** exists at **`android/app/libs/LPTrustedSDK.aar`**.
- [ ] Android: **`justpay.json`** / **`mnv.json`** exist under **`res/raw/`** with correct names.
- [ ] Android: **`network_security_config.xml`** present and referenced in the manifest.
- [ ] iOS: **`LPTrustedSDK.xcframework`** under **`ios/`** and embedded per MID.
- [ ] iOS: JSON files in **Copy Bundle Resources**.
- [ ] iOS: ATS exceptions for the four domains (or MID-approved set).
- [ ] `justpay.json` **`package`** matches Android **`applicationId`**.
- [ ] **`getDeviceId`** returns a **non-empty** string when the SDK is correctly linked (empty often means iOS framework not linked or stub path).
- [ ] **`createIdentityAndSign`** completes with **`success: true`** in a full test onboarding (uses bank sandbox as directed).

---

## 19. Migrating from embedded native JustPay code

If you previously registered a **custom** `MethodChannel` in **`MainActivity`** / **`FlutterActivity`** or **`AppDelegate`** that called LPTrusted directly:

1. Add **`lankapay_justpay_flutter`** to **`pubspec.yaml`**.
2. Remove your custom **JustPay** `MethodChannel` setup and any duplicate **LPTrusted** handler classes from the host app (the plugin registers **`justpay_sdk/methods`** on its own).
3. Replace your Dart bridge class with **`LankapayJustpayFlutter`** from this package.
4. Keep **Firebase**, **notifications**, **other channels**, and **unrelated manifest keys** as they are.
5. Run full **JustPay** regression on Android and iOS.

---

## 20. Troubleshooting

| Symptom | What to check |
|--------|----------------|
| Gradle: AAR not found | Path **`android/app/libs/LPTrustedSDK.aar`** and spelling of filename. |
| Gradle: duplicate classes (`org.apache.commons.io.*` / `org.slf4j.*`) | LPTrustedSDK AAR may already include `commons-io` and `slf4j-api`. Exclude external duplicates in app Gradle using `configurations.configureEach { exclude(...) }` (Kotlin DSL) or `configurations.all { exclude ... }` (Groovy), then run `flutter clean`. |
| Android: “Missing res/raw/…” | Files named **`justpay.json`** / **`mnv.json`** under **`app/src/main/res/raw/`**. |
| Android: cleartext / SSL errors | **`network_security_config.xml`** domains vs MID; manifest **`networkSecurityConfig`**. |
| Android: `package` mismatch | `justpay.json` **`package`** vs **`applicationId`** (flavors). |
| iOS: `import LPTrustedSDK` / link errors | **`ios/LPTrustedSDK.xcframework`**, **`pod install`**, Embed & Sign. |
| iOS: HTTP load fails | **ATS** entries in **Info.plist** for operator hosts. |
| iOS: empty **`getDeviceId`** | Framework not linked (stub path) or SDK not initialized; recheck Embed & Sign, **`ios/LPTrustedSDK.xcframework`** path, and **`pod install`**. |
| Dart: `success: false` with config message | JSON keys missing/wrong; read **`message`** string. |
| Debug logs (recommended) | Android: view **logcat** and filter by tag **`LankapayJustpay`**. iOS: view the **Xcode console** for lines starting with **`[LankapayJustpay]`**. Dart: debug console output (only in debug mode). |
| Debug mocks (optional) | In debug builds you can enable failure simulation as success. This can help you continue UI/backend registration flow without native success. Enable with `LankapayJustpayFlutter(enableDebugMocks: true)`. Backend may still reject dummy `signature` or `mobileReference` if it validates strictly. |
| Release-only crashes | **R8/ProGuard** rules; test **release** on device. |

---

## Quick command recap

```bash
# From app root
flutter pub get
cd ios && pod install && cd ..

# Android
cd android && ./gradlew :app:assembleDebug && cd ..

# iOS (from app root)
flutter build ios --no-codesign
```

If anything in this guide conflicts with your **bank’s MID**, the **MID wins**.
