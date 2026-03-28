package lk.lankapay.justpay_flutter;

import android.content.Context;

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

    private final Context appContext;
    private final LPTrustedSDKManager lpTrustedSDKManager;

    public JustPayNativeBridge(@NonNull Context applicationContext) {
        this.appContext = applicationContext.getApplicationContext();
        this.lpTrustedSDKManager = LPTrustedSDKManager.getInstance(this.appContext);
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getDeviceId":
                result.success(lpTrustedSDKManager.getDeviceID());
                break;
            case "createIdentityAndSign":
                handleCreateIdentityAndSign(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void handleCreateIdentityAndSign(MethodCall call, MethodChannel.Result result) {
        String challenge = call.argument("challenge");
        String contentToSign = call.argument("contentToSign");
        if (challenge == null || challenge.trim().isEmpty()
                || contentToSign == null || contentToSign.trim().isEmpty()) {
            result.success(invalidPayloadResponse());
            return;
        }
        try {
            ensureConfigFilesAvailable();
            startIdentitySignAndValidate(challenge, contentToSign, result, 0);
        } catch (Exception e) {
            HashMap<String, Object> configError = new HashMap<>();
            configError.put("success", false);
            configError.put("message", "JustPay config error: " + e.getMessage());
            configError.put("signature", "");
            configError.put("mobileReference", "");
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

    private void startIdentitySignAndValidate(
            String challenge,
            String contentToSign,
            MethodChannel.Result result,
            int retryCount
    ) {
        try {
            boolean identityExists = lpTrustedSDKManager.isIdentityExist();
            if (identityExists) {
                signAndValidateMobile(contentToSign, result);
                return;
            }

            lpTrustedSDKManager.createIdentity(challenge, new CreateIdentityCallback() {
                @Override
                public void onSuccess() {
                    signAndValidateMobile(contentToSign, result);
                }

                @Override
                public void onFailed(int errorCode, String errorMessage) {
                    if ((errorCode == 300 || errorCode == 301 || errorCode == 302
                            || errorCode == 303 || errorCode == 305) && retryCount < 2) {
                        lpTrustedSDKManager.clearIdentity();
                        startIdentitySignAndValidate(challenge, contentToSign, result, retryCount + 1);
                        return;
                    }
                    sendErrorResult(result, "Identity creation failed (" + errorCode + "): " + errorMessage);
                }
            });
        } catch (Exception e) {
            sendErrorResult(result, "Identity flow failed: " + e.getMessage());
        }
    }

    private void signAndValidateMobile(String contentToSign, MethodChannel.Result result) {
        lpTrustedSDKManager.signMessage(contentToSign, new SignMessageCallback() {
            @Override
            public void onSuccess(String signMessage, String status) {
                lpTrustedSDKManager.validateMobile(new ValidateMobileCallback() {
                    @Override
                    public void onSuccess(String code) {
                        HashMap<String, Object> ok = new HashMap<>();
                        ok.put("success", true);
                        ok.put("message", "OK");
                        ok.put("signature", signMessage == null ? "" : signMessage);
                        ok.put("mobileReference", code == null ? "" : code);
                        result.success(ok);
                    }

                    @Override
                    public void onFailed(int errorCode, String errorMessage) {
                        sendErrorResult(result, "Mobile validation failed (" + errorCode + "): " + errorMessage);
                    }
                });
            }

            @Override
            public void onFailed(int errorCode, String errorMessage) {
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
        result.success(error);
    }

    private void ensureConfigFilesAvailable() throws Exception {
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
        int resId = appContext.getResources().getIdentifier(
                baseName, "raw", appContext.getPackageName());
        if (resId == 0) {
            throw new Exception("Missing res/raw/" + baseName + ".json for package "
                    + appContext.getPackageName());
        }
        InputStream is = appContext.getResources().openRawResource(resId);
        byte[] bytes = new byte[is.available()];
        int read = is.read(bytes);
        is.close();
        if (read <= 0) {
            throw new Exception("Unable to read raw resource: " + baseName);
        }
        return new JSONObject(new String(bytes, StandardCharsets.UTF_8));
    }

    private static void requireKey(JSONObject json, String key) throws Exception {
        String value = json.optString(key, "").trim();
        if (value.isEmpty()) {
            throw new Exception("Missing key: " + key);
        }
    }
}
