import Flutter
import UIKit

public class LankapayJustpayFlutterPlugin: NSObject, FlutterPlugin {
  private let handler = JustPaySdkHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "justpay_sdk/methods",
      binaryMessenger: registrar.messenger()
    )
    let instance = LankapayJustpayFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceId":
      result(handler.deviceId())
    case "createIdentityAndSign":
      guard
        let args = call.arguments as? [String: Any],
        let challenge = args["challenge"] as? String,
        let contentToSign = args["contentToSign"] as? String,
        !challenge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !contentToSign.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result([
          "success": false,
          "message": "Invalid JustPay request payload",
          "signature": "",
          "mobileReference": ""
        ])
        return
      }
      handler.createIdentityAndSign(
        challenge: challenge,
        contentToSign: contentToSign
      ) { payload in
        result(payload)
      }
    case "createIdentityAndSignOnly":
      guard
        let args = call.arguments as? [String: Any],
        let challenge = args["challenge"] as? String,
        let contentToSign = args["contentToSign"] as? String,
        !challenge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !contentToSign.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result([
          "success": false,
          "message": "Invalid JustPay request payload",
          "signature": "",
          "mobileReference": ""
        ])
        return
      }
      handler.createIdentityAndSignOnly(
        challenge: challenge,
        contentToSign: contentToSign
      ) { payload in
        result(payload)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
