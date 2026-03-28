# Example app: `lankapay_justpay_flutter`

This is the bundled **example** Flutter app for the plugin. It is **not** a substitute for the full integration checklist.

## Full A→Z setup (permissions, Android XML, iOS ATS, Gradle, JSON)

Use the canonical guide:

**[../doc/COMPLETE_SETUP_GUIDE.md](../doc/COMPLETE_SETUP_GUIDE.md)**

## Before `flutter run`

1. Copy **`LPTrustedSDK.aar`** → **`android/app/libs/LPTrustedSDK.aar`** (see **`android/app/libs/README.txt`**).
2. Copy **`LPTrustedSDK.xcframework`** → **`ios/JustPaySDK/LPTrustedSDK.xcframework`** (see **`ios/JustPaySDK/README.txt`**).
3. Add bank **`justpay.json`** and **`mnv.json`** to:
   - Android: **`android/app/src/main/res/raw/`**
   - iOS: Runner **Copy Bundle Resources** in Xcode
4. From **`ios/`**: run **`pod install`**.

Without the AAR/xcframework and JSON, native builds will fail or `getDeviceId` may stay empty.

## Run

```bash
cd example
flutter pub get
cd ios && pod install && cd ..
flutter run
```

Short package overview: **[../README.md](../README.md)**
