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
| `mnv.json` | Place in `res/raw` | Required on iOS (add to Runner bundle) |
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
  lankapay_justpay_flutter: ^0.2.22   # or path: / git: for your team
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

**Trade-off (read this if you use `file_picker` 11+ or other Apache Tika stacks):** Excluding external `commons-io` avoids **duplicate class** errors with a fat **`LPTrustedSDK.aar`** that already embeds `org.apache.commons.io.*`. Some dependencies (for example **`file_picker` ≥ 11** on Android, which pulls **`tika-core`**) expect a **full Maven `commons-io` 2.x`** on the classpath. With the exclude, **release R8** can fail with **missing** `org.apache.commons.io.*` classes. In that case you cannot satisfy both AAR and Tika from Gradle alone: **ask the bank / LankaPay for an `LPTrustedSDK` build that does not bundle `commons-io`** (or uses a **relocated** / shaded package), **or** avoid the conflicting stack (for example pin **`file_picker`** to a version **without** `tika-core`, if acceptable for your app). There is no Dart-only fix inside this plugin.

**`applicationId` / flavors:** The value of **`package`** inside `justpay.json` must match the **built app’s** `applicationId` (including flavor suffixes such as `.dev`). If they differ, identity and signing will fail.

### Classpath mirror for LPTrusted (`ClassLoader#getResourceAsStream`)

Some **`LPTrustedSDK`** Android builds load **`justpay.json`** / **`mnv.json`** via the **application class loader**, for example **`context.getClassLoader().getResourceAsStream("res/raw/justpay.json")`** (and the same pattern for **`mnv.json`**). That is **classpath (Java resources)**, not **`Resources.openRawResource`**. Putting files only under **`res/raw`** can satisfy **`openRawResource`** while **`getResourceAsStream("res/raw/…")`** still returns **null** unless those paths also exist as **Java resources** in the APK.

**Fix:** Copy the two JSON files from **`android/app/src/main/res/raw`** into a generated **`res/raw`** tree under **`build/`** during **`preBuild`**, and add that folder to **`android.sourceSets.main.resources`**. Gradle then packages them so the classpath layout matches what the AAR expects; **`ConfigManager.getStatus`** can complete, **`Constants.DEVICE_ID`** can populate, and **`getDeviceID()`** can return a non-empty id in **release** as well as debug.

Kotlin DSL (**`android/app/build.gradle.kts`**) — register the task **outside** **`android { }`**, merge **`sourceSets`** **inside** your existing **`android { }`** block:

```kotlin
// LPTrusted may use ClassLoader.getResourceAsStream("res/raw/justpay.json").
// Mirrors host res/raw JSON into Java resources so that path resolves in the APK.

val prepareLpTrustedClasspathResources =
    tasks.register<Copy>("prepareLpTrustedClasspathResources") {
        from("$projectDir/src/main/res/raw") {
            include("justpay.json", "mnv.json")
        }
        into(layout.buildDirectory.dir("generated/lptrustedClasspathResources/res/raw"))
    }
tasks.named("preBuild").configure { dependsOn(prepareLpTrustedClasspathResources) }

android {
    // ...
    sourceSets {
        getByName("main") {
            resources.srcDir(layout.buildDirectory.dir("generated/lptrustedClasspathResources"))
        }
    }
}
```

Groovy (**`android/app/build.gradle`**) equivalent:

```groovy
tasks.register("prepareLpTrustedClasspathResources", Copy) {
    from("$projectDir/src/main/res/raw") {
        include "justpay.json", "mnv.json"
    }
    into("$buildDir/generated/lptrustedClasspathResources/res/raw")
}
tasks.named("preBuild").configure { dependsOn("prepareLpTrustedClasspathResources") }

android {
    sourceSets {
        main {
            resources.srcDir("$buildDir/generated/lptrustedClasspathResources")
        }
    }
}
```

**Rebuild** your release variant (**`flutter build apk … --release`**, or your flavor) and verify logs (**`deviceIdLength`** should be **> 0**, not **`-1`**; **`getChallenge`** should see a non-empty **`deviceId`**).

**Flavor note:** The snippets copy from **`src/main/res/raw` only**. If flavor-specific trees hold different JSON (**`src/sit/res/raw/`**, etc.), extend the **`Copy`** task with additional **`from(…)`** blocks (or merged inputs) so the generated classpath **`res/raw`** matches what that flavor exposes through **`Resources`** for **`openRawResource`**.

**Optional message for LankaPay / the bank:** If their Android MID assumes **`res/raw`** alone is enough, the integration guide should clarify when config must also be reachable as **`ClassLoader.getResourceAsStream("res/raw/justpay.json")`** / **`…/mnv.json`** — host apps may need this Gradle wiring in addition to standard **`res/raw`** placement.

---

## 6. Android — Config JSON in `res/raw`

1. Copy your bank’s files to:

   - **`android/app/src/main/res/raw/justpay.json`**
   - **`android/app/src/main/res/raw/mnv.json`**

2. **Resource names** are the filenames **without** extension: `justpay` and `mnv`. Do not rename to `justpay_config.json` unless you also change native loading logic (this plugin expects those two names).

3. The plugin validates **required keys** before calling the SDK (see [section 17](#17-config-json--required-keys-reference)).

### Why bridge checks can pass while **`getDeviceId`** stays empty

**Root cause (in the LankaPay Android AAR, not SHA / portal allowlists alone):**

**`LPTrustedSDKManager.getDeviceID()`** does not read **`res/raw`** on every invocation. Typical builds expose a static **`Constants.DEVICE_ID`** populated only after **`ConfigManager.getStatus(context)`** runs successfully — and **`readJPJson(context)`** (and **`readMNVJson`**) must parse your JSON along that path. In some releases of the SDK, **`readJPJson`** uses **`context.getClassLoader().getResourceAsStream("res/raw/justpay.json")`** rather than **`openRawResource`**.

This Flutter plugin validates JSON using **`Resources.openRawResource`** (same logical files as **`res/raw`**). You can therefore see **`bridgeConfigValidation` OK** or a valid **`rawJustpayResId`**, while **`justpay.json`** / **`mnv.json`** are still **missing from the classpath** LPTrusted probes with **`getResourceAsStream("res/raw/…")`**. **`readJPJson`** then fails or **`DEVICE_ID`** is never set, **`getDeviceID()`** is null, and logs may show **`deviceIdLength: -1`**.

Put differently: LankaPay telling you provisioning or SHA has “nothing to configure” reflects **their server side** — this classpath vs **`Resources`** mismatch is **how the client loads config on Android**.

**Remediation:** Implement the **classpath mirror** described in **[section 5](#5-android--gradle-app-module)** (**Classpath mirror for LPTrusted**), then rebuild and re-check **`getDeviceID`** end-to-end.

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

Mobile network validation (MNV) often uses **HTTP** to specific operator endpoints. Android 9+ blocks cleartext unless you allow it per domain. Without the right hosts, you may see **`UnknownServiceException: CLEARTEXT communication … not permitted`**.

UAT/sandbox MNV configs often hit **`3lauth.ideabiz.lk`** and **`gsmacnvep.mobitel.lk`** in addition to production-style **`mobileauth.ideabiz.lk`** and **`gsmacnv.mobitel.lk`**. Include every host your **`mnv.json`** / MID uses.

1. Create **`android/app/src/main/res/xml/network_security_config.xml`**.

2. Example content (merge with **your** MID; add or remove domains per environment):

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">3lauth.ideabiz.lk</domain>
        <domain includeSubdomains="true">mobileauth.ideabiz.lk</domain>
        <domain includeSubdomains="true">gsmacnvep.mobitel.lk</domain>
        <domain includeSubdomains="true">gsmacnv.mobitel.lk</domain>
        <domain includeSubdomains="true">apihub.hutch.lk</domain>
        <domain includeSubdomains="true">heapihub.hutch.lk</domain>
    </domain-config>
</network-security-config>
```

3. Ensure **`AndroidManifest.xml`** references it (see [section 7](#7-android--permissions-androidmanifestxml)).

**Important:** If your bank’s MID lists **different** hosts for sandbox/production, adjust this list. The block above is a **working reference** for common LankaPay MNV hosts, not a substitute for verifying your MID.

---

## 9. Android — ProGuard / R8 (release)

1. This plugin publishes **`android/consumer-rules.pro`**, which Gradle merges into your app when **`minifyEnabled`** is true. **`0.2.22`** restores the **narrow** keeps from **`0.2.18`**:

   ```pro
   -keep class com.lankapay.justpay.** { *; }
   ```

   Fat **`LPTrustedSDK`** AARs often bundle **SpongyCastle**, Apache **Commons**, **OkHttp**, and similar. If **`getDeviceId`** or signing works in **debug** but fails in **release**, add **`-keep`** rules your **MID / bank** documents to your **app module’s** **`proguard-rules.pro`** (for example **`org.spongycastle.**`**, **`lk.lankapay.justpay_flutter.**`, **`org.json.simple.**`**) — they are **not** all declared in this plugin’s consumer rules for **`0.2.22`**.

2. **`ClassLoader` vs Android resources:** Some LPTrusted AAR builds require **`ClassLoader#getResourceAsStream("res/raw/justpay.json")`** (same for **`mnv.json`**). If **`openRawResource`** / plugin validation succeeds but **`getDeviceId`** stays empty (**`deviceIdLength: -1`**, **`getChallenge`** sees no **`deviceId`**), wire the **classpath mirror** from **[section 5](#5-android--gradle-app-module)** (**Classpath mirror for LPTrusted**) before blaming R8 or shrinking alone.

3. **Resource shrinking (`shrinkResources`)** — **not** fixed by **`consumer-rules.pro`**:

   If your app sets **`isShrinkResources = true`** (common with release minify), the build may **remove** **`res/raw/justpay.json`** and **`res/raw/mnv.json`** because they are opened via **`Context#getIdentifier("justpay", "raw", …)`** — the shrinker often **does not** treat that as a reference. LPTrusted then cannot read config → **`getDeviceId()` returns `""`** in **release only** (debug does not shrink). **iOS is unaffected.**

   Add **`app/src/main/res/xml/keep_justpay_raw_resources.xml`** (name optional):

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources xmlns:tools="http://schemas.android.com/tools"
       tools:keep="@raw/justpay,@raw/mnv" />
   ```

   Or temporarily set **`isShrinkResources = false`** to confirm.

4. If **`getDeviceId`** is **non-empty in debug** but **empty in Android release** while **iOS release is fine**, check **(2)** (**classpath**) and **(3)** (**shrinkResources**), then **app-level ProGuard/R8 `-keep` rules** as in **(1)**.

5. If LankaPay or your bank supplies **additional** ProGuard rules, merge them into your app’s **`proguard-rules.pro`** (or the rules file your release build uses).

6. Always run a **release** build on a **real device** and exercise **JustPay onboarding** before store submission.

---

## 10. iOS — LPTrustedSDK and JSON (MID manual Xcode; Flutter disk path)

Follow your **MID Section 7** (LankaPay): copy **`LPTrustedSDK.xcframework`** into the project folder, in Xcode use **Add Files to “…”** on the project, select the xcframework, **Create groups**, enable the **Runner** target, then **Runner → General → Frameworks, Libraries, and Embedded Content** and set **`LPTrustedSDK.xcframework`** to **Embed & Sign**. Add **`justpay.json`** the same way (**Add Files…**), with **Runner** target membership. **`mnv.json`** is required on iOS; add it to **Runner** as well so the plugin can validate **`dialog`** / **`hutch`** / **`mobitel`** before calling the SDK.

**Flutter caveat:** `lankapay_justpay_flutter` is a **separate CocoaPods target**. The plugin pod links **`LPTrustedSDK`** with **`FRAMEWORK_SEARCH_PATHS`** that include **`ios/`**, **`ios/Runner/`**, and common **xcframework slice** folders (**`ios-arm64`**, **`ios-arm64_x86_64-simulator`**, **`ios-arm64-simulator`**) under both **`LPTrustedSDK.xcframework`** locations — the linker needs **`-F`** on the slice that contains **`LPTrustedSDK.framework`**, not only the **`.xcframework`** root. From **0.2.14** this is built into the podspec; upgrade before adding a custom **`Podfile`** `post_install`. After you wire the framework in Xcode, keep the **on-disk** xcframework at **`ios/LPTrustedSDK.xcframework`** or **`ios/Runner/LPTrustedSDK.xcframework`**, then **`cd ios && pod install`**. If your bank’s xcframework uses **other slice directory names**, you can still append those paths in **`post_install`** for the **`lankapay_justpay_flutter`** target (same pattern as slice-specific **`FRAMEWORK_SEARCH_PATHS`**).

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

1. In Xcode, add **`justpay.json`** (**Add Files…**), enable **Runner** target membership, and confirm it under **Build Phases → Copy Bundle Resources**.
2. **`mnv.json`** is **required** on iOS. Add it using the same steps and confirm it is in **Copy Bundle Resources**; the plugin validates **`dialog`**, **`hutch`**, and **`mobitel`**.

Use the literal filenames **`justpay.json`** and **`mnv.json`** so `Bundle.main.url(forResource:withExtension:)` finds them.

---

## 13. iOS — App Transport Security (ATS)

iOS blocks insecure HTTP unless you declare exceptions. Add **`NSAppTransportSecurity`** for the **same operator hosts** you allow in Android cleartext ([section 8](#8-android--network-security-cleartext--mnv)). Use the same domain set as your **`network_security_config.xml`** (UAT often needs **`3lauth.ideabiz.lk`** and **`gsmacnvep.mobitel.lk`**).

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>3lauth.ideabiz.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>mobileauth.ideabiz.lk</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>gsmacnvep.mobitel.lk</key>
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

## 15. iOS — Verify framework, JSON, and Pods

1. Run **`pod install --repo-update`** and open **`Runner.xcworkspace`**.
2. On disk: **`ios/LPTrustedSDK.xcframework`** or **`ios/Runner/LPTrustedSDK.xcframework`** exists.
3. In Xcode (**Runner**): **General → Frameworks, Libraries, and Embedded Content** shows **`LPTrustedSDK.xcframework`** with **Embed & Sign**; both **`justpay.json`** and **`mnv.json`** have **Runner** target membership and are in **Copy Bundle Resources**.

If **`Framework 'LPTrustedSDK' not found`** remains, reconfirm the xcframework on-disk path and rerun **`pod install --repo-update`**.

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

If your flow needs signature only (without MNV/mobile validation), use:

```dart
final signOnly = await justPay.createIdentityAndSignOnly(
  challenge: challengeFromApi,
  contentToSign: termsPlainText,
);

if (signOnly.success) {
  final signature = signOnly.signature;
  // mobileReference is empty in sign-only mode.
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

**Android:** required in **`res/raw`**; keys below must be present and non-empty.

**iOS:** required in the app bundle; keys below must be present and non-empty.

| Key |
|-----|
| `dialog` |
| `hutch` |
| `mobitel` |

If required keys are missing (or **`mnv.json`** is missing on Android/iOS), you get a structured error **`message`** in the Dart result.

---

## 18. Verify the integration

Use this checklist on a **physical device** when possible (MNV often depends on real carrier data).

- [ ] `flutter pub get` succeeds.
- [ ] `cd ios && pod install` succeeds.
- [ ] Android: **`LPTrustedSDK.aar`** exists at **`android/app/libs/LPTrustedSDK.aar`**.
- [ ] Android: **`justpay.json`** / **`mnv.json`** exist under **`res/raw/`** with correct names.
- [ ] Android: If **`getDeviceId`** / diagnostics suggest empty device id despite valid **`res/raw`**, the **classpath mirror** from **[section 5](#5-android--gradle-app-module)** (**Classpath mirror for LPTrusted**) is applied (**`prepareLpTrustedClasspathResources`** + **`sourceSets.main.resources`**).
- [ ] Android: **`network_security_config.xml`** present and referenced in the manifest.
- [ ] iOS: **`LPTrustedSDK.xcframework`** on disk under **`ios/`** or **`ios/Runner/`**; **Runner** → **Embed & Sign**; both **`justpay.json`** and **`mnv.json`** in bundle; **`pod install`** succeeds.
- [ ] iOS: **`justpay.json`** and **`mnv.json`** are in **Copy Bundle Resources**.
- [ ] iOS: ATS **`NSExceptionDomains`** for every MNV HTTP host you use (mirror Android §8; confirm with MID).
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
| Release R8: missing `org.apache.commons.io.*` after excluding `commons-io` | Same trade-off as above: Tika / full `commons-io` vs fat AAR. Prefer an updated **LPTrustedSDK** from the vendor, or remove/downgrade the dependency that pulls **Tika** (often **`file_picker` ≥ 11**). |
| Gradle: duplicate classes **return** when you remove the `commons-io` exclude | Expected: Maven **`commons-io`** and the AAR’s embedded copy both define `org.apache.commons.io.*`. You need a **non-fat** AAR or avoid pulling a second `commons-io`. |
| Android: “Missing res/raw/…” | Files named **`justpay.json`** / **`mnv.json`** under **`app/src/main/res/raw/`**. |
| Android: cleartext / SSL errors | **`network_security_config.xml`** domains vs MID; manifest **`networkSecurityConfig`**. |
| Android: `package` mismatch | `justpay.json` **`package`** vs **`applicationId`** (flavors). |
| Android: **`getDeviceId`** empty (**`deviceIdLength: -1`**) despite **`bridgeConfigValidation` OK** | LPTrusted may load JSON via **`ClassLoader.getResourceAsStream("res/raw/…")`**, not only **`openRawResource`**. Add the classpath mirror in **[section 5](#5-android--gradle-app-module)**. |
| Android: **`getDeviceId`** empty **only in release** | Classpath mirror (**[section 5](#5-android--gradle-app-module)**) when **`res/raw`** looks valid. **`shrinkResources`**: **`tools:keep="@raw/justpay,@raw/mnv"`** (§9) or **`isShrinkResources = false`**. **`R8` stripping embedded AAR deps** (**SpongyCastle**, bridge, etc.) — add **`-keep`** rules in the **app** **`proguard-rules.pro`** per MID; **`0.2.22`** plugin **`consumer-rules`** only keep **`com.lankapay.justpay.**` (see §9). Versions **0.2.19–0.2.21** published wider plugin consumer rules if you prefer that over app rules. |
| iOS: **`Framework 'LPTrustedSDK' not found`** | **`ios/LPTrustedSDK.xcframework`** or **`ios/Runner/`** on disk; **`pod install --repo-update`**; open **`Runner.xcworkspace`**. Use plugin **≥ 0.2.14** (slice **`FRAMEWORK_SEARCH_PATHS`**). |
| iOS: `import LPTrustedSDK` / link errors | Same + **`pod install --repo-update`**; **`Runner.xcworkspace`**. If your xcframework uses unusual slice folder names, append them in **`post_install`** for **`lankapay_justpay_flutter`**. Optional vendored pod. |
| iOS: HTTP load fails | **ATS** entries in **Info.plist** for operator hosts. |
| iOS: empty **`getDeviceId`** | Often **stub** (framework not linked: **`#if canImport(LPTrustedSDK)`** false) — fix xcframework disk path + **`pod install`**. On a linked device build, empty can mean SDK not initialized per MID. |
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
