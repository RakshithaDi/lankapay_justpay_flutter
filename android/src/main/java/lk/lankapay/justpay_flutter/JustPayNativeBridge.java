package lk.lankapay.justpay_flutter;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.lankapay.justpay.LPTrustedSDKManager;
import com.lankapay.justpay.callbacks.CreateIdentityCallback;
import com.lankapay.justpay.callbacks.SignMessageCallback;
import com.lankapay.justpay.callbacks.ValidateMobileCallback;

import org.json.JSONObject;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * LPTrusted / JustPay flows extracted from the host app {@code MainActivity} pattern.
 * Raw JSON is loaded from the <strong>host application</strong> {@code res/raw/} using
 * the application package name (not the plugin’s {@code R} class).
 */
public final class JustPayNativeBridge {

    private static final String TAG = "LankapayJustpay";

    private final Context appContext;
    private final LPTrustedSDKManager lpTrustedSDKManager;

    public JustPayNativeBridge(@NonNull Context applicationContext) {
        this.appContext = applicationContext.getApplicationContext();
        this.lpTrustedSDKManager = LPTrustedSDKManager.getInstance(this.appContext);
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getDeviceId":
                // Use Log.i/Log.e regardless of BuildConfig.DEBUG so release/logcat shows failures.
                Log.i(TAG, "getDeviceId called");
                try {
                    // Same JSON LPTrusted needs internally; fails fast if shrinkResources stripped res/raw.
                    ensureConfigFilesAvailable();
                } catch (Exception e) {
                    Log.e(
                            TAG,
                            "getDeviceId: raw JSON missing or invalid (check res/raw + shrinkResources keep.xml): "
                                    + e.getMessage(),
                            e,
                    );
                    result.success("");
                    break;
                }
                final String deviceId = lpTrustedSDKManager.getDeviceID();
                if (deviceId == null || deviceId.isEmpty()) {
                    Log.e(
                            TAG,
                            "getDeviceId: LPTrusted returned empty "
                                    + "(verify LPTrustedSDK.aar, R8/consumer-rules, and justpay.json package vs applicationId)",
                    );
                } else {
                    Log.i(TAG, "getDeviceId ok length=" + deviceId.length());
                }
                result.success(deviceId == null ? "" : deviceId);
                break;
            case "createIdentityAndSign":
                debugLog("createIdentityAndSign called");
                handleCreateIdentityAndSign(call, result);
                break;
            case "createIdentityAndSignOnly":
                debugLog("createIdentityAndSignOnly called");
                handleCreateIdentityAndSignOnly(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void handleCreateIdentityAndSign(MethodCall call, MethodChannel.Result result) {
        String challenge = call.argument("challenge");
        String contentToSign = call.argument("contentToSign");
        boolean challengeOk = challenge != null && !challenge.trim().isEmpty();
        boolean contentOk = contentToSign != null && !contentToSign.trim().isEmpty();
        if (challenge == null || challenge.trim().isEmpty()
                || contentToSign == null || contentToSign.trim().isEmpty()) {
            if (!challengeOk) {
                debugLog("Invalid payload: challenge is empty");
            }
            if (!contentOk) {
                debugLog("Invalid payload: contentToSign is empty");
            }
            result.success(invalidPayloadResponse());
            return;
        }
        try {
            debugLog("Validating config files (justpay.json and mnv.json) from host res/raw");
            ensureConfigFilesAvailable();
            debugLog("Config validation passed");
            if (Boolean.TRUE.equals(call.argument("recreateIdentityEachCall"))) {
                debugLog("recreateIdentityEachCall=true -> clearIdentity()");
                lpTrustedSDKManager.clearIdentity();
            }
            startIdentitySignAndValidate(challenge, contentToSign, result, 0);
        } catch (Exception e) {
            HashMap<String, Object> configError = new HashMap<>();
            configError.put("success", false);
            configError.put("message", "JustPay config error: " + e.getMessage());
            configError.put("signature", "");
            configError.put("mobileReference", "");
            debugLog("Config/init exception: " + e.getMessage());
            result.success(configError);
        }
    }

    private static HashMap<String, Object> invalidPayloadResponse() {
        HashMap<String, Object> invalidResponse = new HashMap<>();
        invalidResponse.put("success", false);
        invalidResponse.put("message", "Invalid JustPay request payload");
        invalidResponse.put("signature", "");
        invalidResponse.put("mobileReference", "");
        return invalidResponse;
    }

    private static HashMap<String, Object> signingOnlySuccessResponse(String signature) {
        HashMap<String, Object> ok = new HashMap<>();
        ok.put("success", true);
        ok.put("message", "OK");
        ok.put("signature", signature == null ? "" : signature);
        ok.put("mobileReference", "");
        return ok;
    }

    private void handleCreateIdentityAndSignOnly(MethodCall call, MethodChannel.Result result) {
        String challenge = call.argument("challenge");
        String contentToSign = call.argument("contentToSign");
        boolean challengeOk = challenge != null && !challenge.trim().isEmpty();
        boolean contentOk = contentToSign != null && !contentToSign.trim().isEmpty();
        if (challenge == null || challenge.trim().isEmpty()
                || contentToSign == null || contentToSign.trim().isEmpty()) {
            if (!challengeOk) {
                debugLog("Invalid payload: challenge is empty");
            }
            if (!contentOk) {
                debugLog("Invalid payload: contentToSign is empty");
            }
            result.success(invalidPayloadResponse());
            return;
        }
        try {
            debugLog("Validating config files (justpay.json and mnv.json) from host res/raw");
            ensureConfigFilesAvailable();
            debugLog("Config validation passed");
            if (Boolean.TRUE.equals(call.argument("recreateIdentityEachCall"))) {
                debugLog("recreateIdentityEachCall=true -> clearIdentity()");
                lpTrustedSDKManager.clearIdentity();
            }
            startIdentityAndSignOnly(challenge, contentToSign, result, 0);
        } catch (Exception e) {
            HashMap<String, Object> configError = new HashMap<>();
            configError.put("success", false);
            configError.put("message", "JustPay config error: " + e.getMessage());
            configError.put("signature", "");
            configError.put("mobileReference", "");
            debugLog("Config/init exception: " + e.getMessage());
            result.success(configError);
        }
    }

    private void startIdentitySignAndValidate(
            String challenge,
            String contentToSign,
            MethodChannel.Result result,
            int retryCount
    ) {
        try {
            boolean identityExists = lpTrustedSDKManager.isIdentityExist();
            debugLog("LPTrusted identityExists=" + identityExists + " retryCount=" + retryCount);
            if (identityExists) {
                debugLog("Stage=signing (identity exists)");
                signAndValidateMobile(contentToSign, result);
                return;
            }

            debugLog("Stage=creatingIdentity");
            lpTrustedSDKManager.createIdentity(challenge, new CreateIdentityCallback() {
                @Override
                public void onSuccess() {
                    debugLog("Identity creation success -> Stage=signing");
                    signAndValidateMobile(contentToSign, result);
                }

                @Override
                public void onFailed(int errorCode, String errorMessage) {
                    if ((errorCode == 300 || errorCode == 301 || errorCode == 302
                            || errorCode == 303 || errorCode == 305) && retryCount < 2) {
                        debugLog("Identity creation failed (retryable) errorCode=" + errorCode + " -> clearIdentity and retry");
                        lpTrustedSDKManager.clearIdentity();
                        startIdentitySignAndValidate(challenge, contentToSign, result, retryCount + 1);
                        return;
                    }
                    debugLog("Identity creation failed errorCode=" + errorCode + " message=" + errorMessage);
                    sendErrorResult(result, "Identity creation failed (" + errorCode + "): " + errorMessage);
                }
            });
        } catch (Exception e) {
            debugLog("Identity flow exception: " + e.getMessage());
            sendErrorResult(result, "Identity flow failed: " + e.getMessage());
        }
    }

    private void signAndValidateMobile(String contentToSign, MethodChannel.Result result) {
        debugLog("Stage=signing (signMessage called)");
        lpTrustedSDKManager.signMessage(contentToSign, new SignMessageCallback() {
            @Override
            public void onSuccess(String signMessage, String status) {
                boolean signaturePresent = signMessage != null && !signMessage.isEmpty();
                debugLog("signMessage success stage=validatingMobile signaturePresent=" + signaturePresent
                        + " signatureLen=" + (signaturePresent ? signMessage.length() : 0)
                        + " status=" + status);
                lpTrustedSDKManager.validateMobile(new ValidateMobileCallback() {
                    @Override
                    public void onSuccess(String code) {
                        boolean tokenPresent = code != null && !code.isEmpty();
                        debugLog("validateMobile success tokenPresent=" + tokenPresent
                                + " tokenLen=" + (tokenPresent ? code.length() : 0));
                        HashMap<String, Object> ok = new HashMap<>();
                        ok.put("success", true);
                        ok.put("message", "OK");
                        ok.put("signature", signMessage == null ? "" : signMessage);
                        ok.put("mobileReference", code == null ? "" : code);
                        result.success(ok);
                    }

                    @Override
                    public void onFailed(int errorCode, String errorMessage) {
                        debugLog("validateMobile failed errorCode=" + errorCode + " message=" + errorMessage);
                        sendErrorResult(result, "Mobile validation failed (" + errorCode + "): " + errorMessage);
                    }
                });
            }

            @Override
            public void onFailed(int errorCode, String errorMessage) {
                debugLog("signMessage failed errorCode=" + errorCode + " message=" + errorMessage);
                sendErrorResult(result, "Message signing failed (" + errorCode + "): " + errorMessage);
            }
        });
    }

    private void startIdentityAndSignOnly(
            String challenge,
            String contentToSign,
            MethodChannel.Result result,
            int retryCount
    ) {
        try {
            boolean identityExists = lpTrustedSDKManager.isIdentityExist();
            debugLog("LPTrusted identityExists=" + identityExists + " retryCount=" + retryCount + " signingOnly=true");
            if (identityExists) {
                debugLog("Stage=signingOnly (identity exists)");
                signOnly(contentToSign, result);
                return;
            }

            debugLog("Stage=creatingIdentity signingOnly=true");
            lpTrustedSDKManager.createIdentity(challenge, new CreateIdentityCallback() {
                @Override
                public void onSuccess() {
                    debugLog("Identity creation success -> Stage=signingOnly");
                    signOnly(contentToSign, result);
                }

                @Override
                public void onFailed(int errorCode, String errorMessage) {
                    if ((errorCode == 300 || errorCode == 301 || errorCode == 302
                            || errorCode == 303 || errorCode == 305) && retryCount < 2) {
                        debugLog("Identity creation failed (retryable) errorCode=" + errorCode + " -> clearIdentity and retry");
                        lpTrustedSDKManager.clearIdentity();
                        startIdentityAndSignOnly(challenge, contentToSign, result, retryCount + 1);
                        return;
                    }
                    debugLog("Identity creation failed errorCode=" + errorCode + " message=" + errorMessage);
                    sendErrorResult(result, "Identity creation failed (" + errorCode + "): " + errorMessage);
                }
            });
        } catch (Exception e) {
            debugLog("Identity flow exception: " + e.getMessage());
            sendErrorResult(result, "Identity flow failed: " + e.getMessage());
        }
    }

    private void signOnly(String contentToSign, MethodChannel.Result result) {
        debugLog("Stage=signingOnly (signMessage called)");
        lpTrustedSDKManager.signMessage(contentToSign, new SignMessageCallback() {
            @Override
            public void onSuccess(String signMessage, String status) {
                boolean signaturePresent = signMessage != null && !signMessage.isEmpty();
                debugLog("signMessage success (signingOnly) signaturePresent=" + signaturePresent
                        + " signatureLen=" + (signaturePresent ? signMessage.length() : 0)
                        + " status=" + status);
                result.success(signingOnlySuccessResponse(signMessage));
            }

            @Override
            public void onFailed(int errorCode, String errorMessage) {
                debugLog("signMessage failed errorCode=" + errorCode + " message=" + errorMessage);
                sendErrorResult(result, "Message signing failed (" + errorCode + "): " + errorMessage);
            }
        });
    }

    private static void sendErrorResult(MethodChannel.Result result, String message) {
        HashMap<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("message", message);
        error.put("signature", "");
        error.put("mobileReference", "");
        debugStaticLog(message);
        result.success(error);
    }

    private void ensureConfigFilesAvailable() throws Exception {
        debugLog("Loading and validating json keys: justpay.json and mnv.json");
        JSONObject justPay = loadRawJson("justpay");
        JSONObject mnv = loadRawJson("mnv");

        requireKey(justPay, "url");
        requireKey(justPay, "package");
        requireKey(justPay, "justpay_code");
        requireKey(justPay, "key_encipher");
        requireKey(justPay, "key_signer");
        requireKey(justPay, "justpay_cert");
        requireKey(justPay, "issuer");

        requireKey(mnv, "dialog");
        requireKey(mnv, "hutch");
        requireKey(mnv, "mobitel");
    }

    private JSONObject loadRawJson(String baseName) throws Exception {
        debugLog("Loading res/raw/" + baseName + ".json for package " + appContext.getPackageName());
        int resId = appContext.getResources().getIdentifier(
                baseName, "raw", appContext.getPackageName());
        if (resId == 0) {
            debugLog("Missing res/raw/" + baseName + ".json (resource not found)");
            throw new Exception("Missing res/raw/" + baseName + ".json for package "
                    + appContext.getPackageName());
        }
        InputStream is = appContext.getResources().openRawResource(resId);
        byte[] bytes = new byte[is.available()];
        int read = is.read(bytes);
        is.close();
        if (read <= 0) {
            debugLog("Unable to read res/raw/" + baseName + ".json bytes");
            throw new Exception("Unable to read raw resource: " + baseName);
        }
        debugLog("Loaded " + baseName + ".json bytes=" + read);
        return new JSONObject(new String(bytes, StandardCharsets.UTF_8));
    }

    private static void requireKey(JSONObject json, String key) throws Exception {
        String value = json.optString(key, "").trim();
        if (value.isEmpty()) {
            debugStaticLog("Missing required json key: " + key);
            throw new Exception("Missing key: " + key);
        }
    }

    private void debugLog(String message) {
        debugStaticLog(message);
    }

    private static void debugStaticLog(String message) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, message);
        }
    }
}
