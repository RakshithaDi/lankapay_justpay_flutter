# LPTrustedSDKManager API (from SDK binaries)

This file documents methods exposed by the actual SDK binaries you provided:

- Android: `/Users/ideahub/pabc-flutter-client-companion/android/app/libs/LPTrustedSDK.aar`
- iOS: `/Users/ideahub/pabc-flutter-client-companion/ios/LPTrustedSDK.xcframework`

It is not inferred from the plugin bridge code.

---

## Android: `com.lankapay.justpay.LPTrustedSDKManager`

Extracted from `classes.jar` inside the AAR (public/protected API signatures).

### Factory / setup

- `static LPTrustedSDKManager getInstance(Context context)`
  - **Required params:** `context`
  - **Returns (value received):** `LPTrustedSDKManager` manager singleton instance
- `void setDebugOn()`
  - **Required params:** none
  - **Returns (value received):** no direct value (`void`)

### Device / version

- `String getDeviceID()`
  - **Required params:** none
  - **Returns (value received):** `deviceId` string
    - Usually a device identifier used for backend/device binding flows.
- `String getVersion()`
  - **Required params:** none
  - **Returns (value received):** SDK version string (for diagnostics/support)

### Identity management

- `void clearIdentity()`
  - **Returns (value received):** no direct value (`void`)
- `void clearAllIdentity()`
  - **Returns (value received):** no direct value (`void`)
- `void clearIdentity(String justpayCode)`
  - **Required params:** `justpayCode`
  - **Returns (value received):** no direct value (`void`)
- `String getAllIdentities()`
  - **Returns (value received):** serialized/string representation of identities managed by SDK
- `boolean isIdentityExist()`
  - **Returns (value received):**
    - `true`: default identity exists
    - `false`: default identity does not exist
- `boolean isIdentityExist(String justpayCode)`
  - **Required params:** `justpayCode`
  - **Returns (value received):**
    - `true`: identity exists for that code
    - `false`: identity does not exist for that code

### Core JustPay flow

- `void createIdentity(String challenge, CreateIdentityCallback callback)`
  - **Required params:** `challenge`, `callback`
  - **Values received via callback:**
    - success: `onSuccess()`
    - failure: `onFailed(errorCode, errorMessage)`
- `void createIdentity(String justpayCode, String challenge, CreateIdentityCallback callback)`
  - **Required params:** `justpayCode`, `challenge`, `callback`
  - **Values received via callback:**
    - success: `onSuccess()`
    - failure: `onFailed(errorCode, errorMessage)`
- `void signMessage(String message, SignMessageCallback callback)`
  - **Required params:** `message`, `callback`
  - **Values received via callback:**
    - success: `onSuccess(signedMessage, status)`
      - `signedMessage`: digital signature string
      - `status`: SDK-provided signing status (for example, values like `VERIFIED` may appear)
    - failure: `onFailed(errorCode, errorMessage)`
- `void signMessage(String justpayCode, String message, SignMessageCallback callback)`
  - **Required params:** `justpayCode`, `message`, `callback`
  - **Values received via callback:**
    - success: `onSuccess(signedMessage, status)`
      - `signedMessage`: digital signature string
      - `status`: signing status text
    - failure: `onFailed(errorCode, errorMessage)`
- `void validateMobile(ValidateMobileCallback callback)`
  - **Required params:** `callback`
  - **Values received via callback:**
    - success: `onSuccess(codeOrToken)`
      - `codeOrToken`: mobile validation token/reference (plugin maps this as `mobileReference`)
    - failure: `onFailed(errorCode, errorMessage)`
- `void validateMobile(String justpayCode, ValidateMobileCallback callback)`
  - **Required params:** `justpayCode`, `callback`
  - **Values received via callback:**
    - success: `onSuccess(codeOrToken)`
      - `codeOrToken`: mobile validation token/reference
    - failure: `onFailed(errorCode, errorMessage)`

---

## Android callback interfaces (SDK)

### `CreateIdentityCallback`
- `void onSuccess()`
  - **Values received:** none (just success signal)
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:**
    - `errorCode`: integer failure code
    - `errorMessage`: human-readable failure message

### `SignMessageCallback`
- `void onSuccess(String signedMessage, String status)`
  - **Values received:**
    - `signedMessage`: generated digital signature
    - `status`: signing status text
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:**
    - `errorCode`: integer failure code
    - `errorMessage`: human-readable failure message

### `ValidateMobileCallback`
- `void onSuccess(String codeOrToken)`
  - **Values received:**
    - `codeOrToken`: mobile validation reference/token
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:**
    - `errorCode`: integer failure code
    - `errorMessage`: human-readable failure message

### Additional callback interfaces present in AAR

#### `IdentityCallback`
- `void onSuccess(com.lankapay.justpay.classes.Identity identity)`
  - **Values received:** `identity` object
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:** `errorCode`, `errorMessage`

#### `CSRCallback`
- `void onSuccess(com.lankapay.justpay.classes.SignedCSR signedCSR, com.lankapay.justpay.classes.IdentityAttributes identityAttributes)`
  - **Values received:** `signedCSR` object, `identityAttributes` object
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:** `errorCode`, `errorMessage`

#### `CertificateStatusCallback`
- `void onSuccess(String status)`
  - **Values received:** `status` string
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:** `errorCode`, `errorMessage`

#### `UploadCertificateCallback`
- `void onSuccess(com.lankapay.justpay.classes.IdentityAttributes identityAttributes)`
  - **Values received:** `identityAttributes` object
- `void onFailed(int errorCode, String errorMessage)`
  - **Values received:** `errorCode`, `errorMessage`

---

## iOS: `LPTrustedSDKManager` (from framework header)

Extracted from:

- `LPTrustedSDK.xcframework/ios-arm64/LPTrustedSDK.framework/Headers/LPTrustedSDK.h`

### Property

- `@property (weak) id<LPTrustedSDKDelegate> delegate;`
  - **Purpose:** receives async callback values from identity/sign/validate operations

### Factory

- `+ (id)getInstance;`
  - **Returns (value received):** singleton `LPTrustedSDKManager` instance

### Core JustPay flow

- `- (void)createIdentity:(NSString *)challenge;`
  - **Required params:** `challenge`
  - **Values received via delegate:**
    - success: `onIdentitySuccess`
    - failure: `onIdentityFailed(errorCode, errorMessage)`
- `- (void)createIdentity:(NSString *)justpayCode challenge:(NSString *)challenge;`
  - **Required params:** `justpayCode`, `challenge`
  - **Values received via delegate:**
    - success: `onIdentitySuccess`
    - failure: `onIdentityFailed(errorCode, errorMessage)`
- `- (void)signMessage:(NSString *)message;`
  - **Required params:** `message`
  - **Values received via delegate:**
    - success: `onMessageSignSuccess(signedMessage, status)`
      - `signedMessage`: digital signature
      - `status`: signing status text
    - failure: `onMessageSignFailed(errorCode, errorMessage)`
- `- (void)signMessage:(NSString *)justpayCode message:(NSString *)message;`
  - **Required params:** `justpayCode`, `message`
  - **Values received via delegate:**
    - success: `onMessageSignSuccess(signedMessage, status)`
      - `signedMessage`: digital signature
      - `status`: signing status text
    - failure: `onMessageSignFailed(errorCode, errorMessage)`
- `- (void)validateMobile;`
  - **Values received via delegate:**
    - success: `onValidateMobileSuccess(token)`
      - `token`: mobile validation token/reference
    - failure: `onValidateMobileFailed(errorCode, errorMessage)`
- `- (void)validateMobile:(NSString *)justpayCode;`
  - **Required params:** `justpayCode`
  - **Values received via delegate:**
    - success: `onValidateMobileSuccess(token)`
      - `token`: mobile validation token/reference
    - failure: `onValidateMobileFailed(errorCode, errorMessage)`

### Identity / device / version

- `- (BOOL)isIdentityExist;`
  - **Returns (value received):** `YES`/`NO` for default identity existence
- `- (BOOL)isIdentityExist:(NSString *)justpayCode;`
  - **Required params:** `justpayCode`
  - **Returns (value received):** `YES`/`NO` for that code's identity existence
- `- (BOOL)clearIdentity;`
  - **Returns (value received):** `YES`/`NO` (whether clear action succeeded)
- `- (BOOL)clearIdentity:(NSString *)justpayCode;`
  - **Required params:** `justpayCode`
  - **Returns (value received):** `YES`/`NO` (whether clear action succeeded for that code)
- `- (NSString *)getDeviceId;`
  - **Returns (value received):** device id string
- `- (NSString *)getVersion;`
  - **Returns (value received):** SDK version string

---

## iOS delegate response methods: `LPTrustedSDKDelegate`

- `- (void)onIdentitySuccess;`
  - **Values received:** none (success signal)
- `- (void)onIdentityFailed:(int)errorCode message:(NSString *)errorMessage;`
  - **Values received:** `errorCode`, `errorMessage`
- `- (void)onMessageSignSuccess:(NSString *)signedMessage status:(NSString *)status;`
  - **Values received:** `signedMessage` (signature), `status`
- `- (void)onMessageSignFailed:(int)errorCode message:(NSString *)errorMessage;`
  - **Values received:** `errorCode`, `errorMessage`
- `- (void)onValidateMobileSuccess:(NSString *)token;`
  - **Values received:** `token` (mobile validation token/reference)
- `- (void)onValidateMobileFailed:(NSInteger)errorCode message:(NSString *)errorMessage;`
  - **Values received:** `errorCode`, `errorMessage`

