import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/justpay_sdk_result.dart';

export 'src/justpay_sdk_result.dart';

/// Flutter bridge to the LankaPay LPTrusted (JustPay) native SDK.
///
/// The host app must supply [justpay.json] and [mnv.json], link the LPTrusted
/// binaries, and complete MID host configuration. This class only forwards calls
/// over the method channel `justpay_sdk/methods`.
class LankapayJustpayFlutter {
  LankapayJustpayFlutter({
    MethodChannel? channel,
    bool enableDebugLogs = kDebugMode,
  })  : _channel = channel ?? const MethodChannel(_kChannelName),
        _enableDebugLogs = enableDebugLogs;

  static const String _kChannelName = 'justpay_sdk/methods';

  final MethodChannel _channel;
  final bool _enableDebugLogs;

  bool get _debugEnabled => _enableDebugLogs && kDebugMode;

  /// LPTrusted device identifier (empty string if the native side returns null).
  Future<String> getDeviceId() async {
    if (_debugEnabled) {
      debugPrint('[LankapayJustpayFlutter] getDeviceId called');
    }
    final value = await _channel.invokeMethod<String>('getDeviceId');
    if (_debugEnabled) {
      final present = value != null && value.isNotEmpty;
      final len = value?.length ?? 0;
      debugPrint(
        '[LankapayJustpayFlutter] getDeviceId response present=$present len=$len',
      );
    }
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
    if (_debugEnabled) {
      debugPrint(
        '[LankapayJustpayFlutter] createIdentityAndSign called challengeLen=${challenge.length} contentToSignLen=${contentToSign.length}',
      );
    }
    Map<String, dynamic>? map;
    try {
      map = await _channel.invokeMapMethod<String, dynamic>(
        'createIdentityAndSign',
        {
          'challenge': challenge,
          'contentToSign': contentToSign,
        },
      );
    } catch (e) {
      if (_debugEnabled) {
        debugPrint('[LankapayJustpayFlutter] createIdentityAndSign failed with exception: $e');
      }
      rethrow;
    }

    if (map == null) {
      if (_debugEnabled) {
        debugPrint('[LankapayJustpayFlutter] createIdentityAndSign returned null map');
      }
      return const JustPaySdkResult(
        success: false,
        message: 'Empty SDK response',
      );
    }

    final result = JustPaySdkResult.fromMap(map);
    if (_debugEnabled) {
      final sig = result.signature;
      final token = result.mobileReference;
      debugPrint(
        '[LankapayJustpayFlutter] createIdentityAndSign result success=${result.success} messageLen=${result.message?.length ?? 0} signaturePresent=${sig != null && sig.isNotEmpty} signatureLen=${sig?.length ?? 0} mobileReferencePresent=${token != null && token.isNotEmpty} mobileReferenceLen=${token?.length ?? 0}',
      );
    }
    return result;
  }
}
