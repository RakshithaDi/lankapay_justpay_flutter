import 'package:flutter/services.dart';

import 'src/justpay_sdk_result.dart';

export 'src/justpay_sdk_result.dart';

/// Flutter bridge to the LankaPay LPTrusted (JustPay) native SDK.
///
/// The host app must supply [justpay.json] and [mnv.json], link the LPTrusted
/// binaries, and complete MID host configuration. This class only forwards calls
/// over the method channel `justpay_sdk/methods`.
class LankapayJustpayFlutter {
  LankapayJustpayFlutter({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_kChannelName);

  static const String _kChannelName = 'justpay_sdk/methods';

  final MethodChannel _channel;

  /// LPTrusted device identifier (empty string if the native side returns null).
  Future<String> getDeviceId() async {
    final value = await _channel.invokeMethod<String>('getDeviceId');
    return value ?? '';
  }

  /// Creates identity when needed, signs [contentToSign], then validates mobile.
  ///
  /// [challenge] comes from your bank’s JustPay API; [contentToSign] is typically
  /// the terms text the user agreed to (see your integration guide).
  Future<JustPaySdkResult> createIdentityAndSign({
    required String challenge,
    required String contentToSign,
  }) async {
    final map = await _channel.invokeMapMethod<String, dynamic>(
      'createIdentityAndSign',
      {
        'challenge': challenge,
        'contentToSign': contentToSign,
      },
    );
    if (map == null) {
      return const JustPaySdkResult(
        success: false,
        message: 'Empty SDK response',
      );
    }
    return JustPaySdkResult.fromMap(map);
  }
}
