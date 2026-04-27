import Foundation

#if canImport(LPTrustedSDK)
import LPTrustedSDK

final class JustPaySdkHandler: NSObject, LPTrustedSDKDelegate {
  private enum Stage {
    case idle
    case creatingIdentity
    case signing
    case validatingMobile
  }

  private let manager: LPTrustedSDKManager
  private var stage: Stage = .idle
  private var completion: (([String: Any]) -> Void)?
  private var justPayCode: String = ""
  private var signature: String = ""
  private var contentToSign: String = ""

  private func debugLog(_ message: String) {
    #if DEBUG
    print("[LankapayJustpay] \(message)")
    #endif
  }

  override init() {
    guard let sdkManager = LPTrustedSDKManager.getInstance() as? LPTrustedSDKManager else {
      fatalError("LPTrustedSDKManager instance unavailable")
    }
    manager = sdkManager
    super.init()
    manager.delegate = self
  }

  func deviceId() -> String {
    let id = manager.getDeviceId() ?? ""
    debugLog("getDeviceId called present=\(!id.isEmpty) len=\(id.count)")
    return id
  }

  func createIdentityAndSign(
    challenge: String,
    contentToSign: String,
    completion: @escaping ([String: Any]) -> Void
  ) {
    debugLog(
      "createIdentityAndSign called challengeLen=\(challenge.count) contentToSignLen=\(contentToSign.count)"
    )
    self.completion = completion
    do {
      let justPayConfig = try loadJson(named: "justpay")

      debugLog("validating required json keys for justpay.json")
      try require(justPayConfig, "url")
      try require(justPayConfig, "package")
      try require(justPayConfig, "justpay_code")
      try require(justPayConfig, "key_encipher")
      try require(justPayConfig, "key_signer")
      try require(justPayConfig, "justpay_cert")
      try require(justPayConfig, "issuer")

      if let mnvConfig = try loadJsonIfPresent(named: "mnv") {
        debugLog("mnv.json present; validating dialog, hutch, mobitel")
        try require(mnvConfig, "dialog")
        try require(mnvConfig, "hutch")
        try require(mnvConfig, "mobitel")
      } else {
        debugLog("mnv.json not in bundle; skipping validation (not required on iOS)")
      }

      justPayCode = try require(justPayConfig, "justpay_code")
      signature = ""
      self.contentToSign = contentToSign

      if manager.isIdentityExist(justPayCode) {
        debugLog("identityExists=true -> stage=signing")
        stage = .signing
        manager.signMessage(justPayCode, message: self.contentToSign)
      } else {
        debugLog("identityExists=false -> stage=creatingIdentity")
        stage = .creatingIdentity
        manager.createIdentity(justPayCode, challenge: challenge)
      }
    } catch {
      finish(
        success: false,
        message: "JustPay config/init error: \(error.localizedDescription)",
        signature: "",
        mobileReference: ""
      )
    }
  }

  func onIdentitySuccess() {
    guard stage == .creatingIdentity else { return }
    debugLog("onIdentitySuccess -> stage=signing")
    stage = .signing
    manager.signMessage(justPayCode, message: contentToSign)
  }

  func onIdentityFailed(_ errorCode: Int32, message errorMessage: String) {
    debugLog("onIdentityFailed errorCode=\(errorCode) message=\(errorMessage)")
    finish(
      success: false,
      message: "Identity creation failed (\(errorCode)): \(errorMessage)",
      signature: "",
      mobileReference: ""
    )
  }

  func onMessageSignSuccess(_ signedMessage: String, status: String) {
    guard stage == .signing else { return }
    let signaturePresent = !signedMessage.isEmpty
    debugLog(
      "onMessageSignSuccess -> stage=validatingMobile signaturePresent=\(signaturePresent) signatureLen=\(signedMessage.count)"
    )
    signature = signedMessage
    stage = .validatingMobile
    manager.validateMobile(justPayCode)
  }

  func onMessageSignFailed(_ errorCode: Int32, message errorMessage: String) {
    debugLog("onMessageSignFailed errorCode=\(errorCode) message=\(errorMessage)")
    finish(
      success: false,
      message: "Message signing failed (\(errorCode)): \(errorMessage)",
      signature: "",
      mobileReference: ""
    )
  }

  func onValidateMobileSuccess(_ token: String) {
    debugLog("onValidateMobileSuccess tokenLen=\(token.count)")
    finish(success: true, message: "OK", signature: signature, mobileReference: token)
  }

  func onValidateMobileFailed(_ errorCode: Int, message errorMessage: String) {
    debugLog("onValidateMobileFailed errorCode=\(errorCode) message=\(errorMessage)")
    finish(
      success: false,
      message: "Mobile validation failed (\(errorCode)): \(errorMessage)",
      signature: "",
      mobileReference: ""
    )
  }

  private func finish(success: Bool, message: String, signature: String, mobileReference: String) {
    stage = .idle
    debugLog(
      "finish success=\(success) signaturePresent=\(!signature.isEmpty) signatureLen=\(signature.count) mobileRefLen=\(mobileReference.count)"
    )
    let payload: [String: Any] = [
      "success": success,
      "message": message,
      "signature": signature,
      "mobileReference": mobileReference
    ]
    DispatchQueue.main.async { [weak self] in
      self?.completion?(payload)
      self?.completion = nil
    }
  }

  private func loadJson(named name: String) throws -> [String: Any] {
    debugLog("loading \(name).json from main bundle")
    guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
      debugLog("\(name).json not found in main bundle")
      throw NSError(
        domain: "JustPay",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "\(name).json not found in app bundle"]
      )
    }
    let data = try Data(contentsOf: url)
    debugLog("\(name).json read bytes=\(data.count)")
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    guard let json = object as? [String: Any] else {
      debugLog("\(name).json is not a valid JSON object")
      throw NSError(
        domain: "JustPay",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey: "\(name).json is not a valid JSON object"]
      )
    }
    return json
  }

  /// Returns `nil` if the file is absent (iOS does not require `mnv.json` in the app bundle).
  private func loadJsonIfPresent(named name: String) throws -> [String: Any]? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
      return nil
    }
    let data = try Data(contentsOf: url)
    debugLog("\(name).json read bytes=\(data.count)")
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    guard let json = object as? [String: Any] else {
      debugLog("\(name).json is not a valid JSON object")
      throw NSError(
        domain: "JustPay",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey: "\(name).json is not a valid JSON object"]
      )
    }
    return json
  }

  private func require(_ json: [String: Any], _ key: String) throws -> String {
    guard let value = json[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      debugLog("Missing required key: '\(key)'")
      throw NSError(domain: "JustPay", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing key '\(key)'"])
    }
    return value
  }
}

#else

/// Stub when `LPTrustedSDK` is not linked. Per README: MID-style Xcode embed on Runner plus
/// `LPTrustedSDK.xcframework` on disk under `ios/` or `ios/Runner/`, then `pod install`.
/// Optional `LPTrustedSDK_Vendored` path pod if the plugin target still cannot resolve the framework.
final class JustPaySdkHandler: NSObject {
  private func debugLog(_ message: String) {
    #if DEBUG
    print("[LankapayJustpay] \(message)")
    #endif
  }

  func deviceId() -> String {
    debugLog(
      "getDeviceId stub: LPTrustedSDK not linked (#if canImport false). "
        + "Place LPTrustedSDK.xcframework under ios/ or ios/Runner/, Embed & Sign on Runner, pod install; "
        + "optional LPTrustedSDK_Vendored per README."
    )
    return ""
  }

  func createIdentityAndSign(
    challenge: String,
    contentToSign: String,
    completion: @escaping ([String: Any]) -> Void
  ) {
    debugLog(
      "LPTrustedSDK not linked; stub handler called (challengeLen=\(challenge.count) contentToSignLen=\(contentToSign.count))"
    )
    let payload: [String: Any] = [
      "success": false,
      "message":
        "LPTrustedSDK is not linked. Add LPTrustedSDK.xcframework under ios/ or ios/Runner/, "
        + "Embed & Sign on Runner, run pod install (see plugin README); optional LPTrustedSDK_Vendored if needed.",
      "signature": "",
      "mobileReference": ""
    ]
    DispatchQueue.main.async {
      completion(payload)
    }
  }
}

#endif
