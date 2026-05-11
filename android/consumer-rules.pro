# =============================================================================
# LankaPay LPTrusted / JustPay — merged into host apps that minify (R8).
# =============================================================================
# LPTrustedSDK.aar ships SpongyCastle as org.spongycastle.** (libs/sc*-jdk15on),
# not org.bouncycastle. If consumer rules only keep com.lankapay.justpay.**,
# release builds can break crypto / ConfigManager device-id paths → getDeviceId ""
# while debug (no minify) works. iOS is unaffected.
#
# Host apps should not need to duplicate these when using a current plugin version.
#
# --- shrinkResources (host app) ---
# ProGuard/R8 cannot keep Android *resources*. If the app uses shrinkResources=true,
# `res/raw/justpay.json` and `res/raw/mnv.json` may be removed when loaded only via
# Context#getIdentifier(name,"raw",...) — LPTrusted then fails silently → empty getDeviceId.
# Fix: add res/xml + tools:keep for @raw/justpay,@raw/mnv (see plugin COMPLETE_SETUP_GUIDE §9).

# LPTrusted Java API + callbacks + embedded HTTP/crypto stack
-keep class com.lankapay.justpay.** { *; }
-keep interface com.lankapay.justpay.** { *; }

# SpongyCastle (bundled inside LPTrustedSDK.aar; required for signing / device id)
-keep class org.spongycastle.** { *; }
-dontwarn org.spongycastle.**

# Apache Commons + json-simple (often loaded reflectively from LPTrusted / MNV)
-keep class org.apache.commons.codec.** { *; }
-keep class org.apache.commons.lang3.** { *; }
-keep class org.apache.commons.io.** { *; }
-keep class org.json.simple.** { *; }

# MethodChannel entry points (Flutter registers the plugin; keeps bridge stable under R8)
-keep class lk.lankapay.justpay_flutter.** { *; }

# OkHttp (direct dependency of this plugin; PublicSuffix DB is a common R8 pitfall)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
