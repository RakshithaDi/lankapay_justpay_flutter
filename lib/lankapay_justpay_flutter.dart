import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/justpay_sdk_result.dart';

export 'src/justpay_sdk_result.dart';

/// Flutter bridge to the LankaPay LPTrusted (JustPay) native SDK.
///
/// The host app must supply [justpay.json], link the LPTrusted binaries, and
/// complete MID host configuration. [mnv.json] is required on Android; on iOS it
/// is optional if your integration does not bundle it. This class only forwards calls
/// over the method channel `justpay_sdk/methods`.
class LankapayJustpayFlutter {
  LankapayJustpayFlutter({
    MethodChannel? channel,
    bool enableDebugLogs = kDebugMode,
    bool enableDebugMocks = false,
  })  : _channel = channel ?? const MethodChannel(_kChannelName),
        _enableDebugLogs = enableDebugLogs,
        _enableDebugMocks = enableDebugMocks;

  static const String _kChannelName = 'justpay_sdk/methods';

  static const String _kSimulatedMessage = 'SIMULATED_SUCCESS (debug mocks enabled)';
  static const String _kSimulatedSignature = 'DEBUG_SIGNATURE_DUMMY';
  static const String _kSimulatedMobileReference = 'DEBUG_MNV_TOKEN_DUMMY';

  static const JustPaySdkResult _kSimulatedSuccessResult = JustPaySdkResult(
    success: true,
    message: _kSimulatedMessage,
    signature: _kSimulatedSignature,
    mobileReference: _kSimulatedMobileReference,
  );

  final MethodChannel _channel;
  final bool _enableDebugLogs;
  final bool _enableDebugMocks;

  bool get _debugEnabled => _enableDebugLogs && kDebugMode;
  bool get _debugMocksEnabled => _enableDebugMocks && kDebugMode;

  static JustPaySdkResult _simulatedSuccessResult() => _kSimulatedSuccessResult;

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
      if (_debugMocksEnabled) {
        if (_debugEnabled) {
          debugPrint('[LankapayJustpayFlutter] Debug mocks: simulating success from null map');
        }
        return _simulatedSuccessResult();
      }
      return const JustPaySdkResult(
        success: false,
        message: 'Empty SDK response',
      );
    }

    final result = JustPaySdkResult.fromMap(map);
    if (!result.success && _debugMocksEnabled) {
      if (_debugEnabled) {
        debugPrint(
          '[LankapayJustpayFlutter] Debug mocks: native returned success=false, simulating success',
        );
      }
      return _simulatedSuccessResult();
    }
    if (_debugEnabled) {
      final sig = result.signature;
      final token = result.mobileReference;
      debugPrint(
        '[LankapayJustpayFlutter] createIdentityAndSign result success=${result.success} messageLen=${result.message?.length ?? 0} signaturePresent=${sig != null && sig.isNotEmpty} signatureLen=${sig?.length ?? 0} mobileReferencePresent=${token != null && token.isNotEmpty} mobileReferenceLen=${token?.length ?? 0}',
      );
    }
    return result;
  }

  /// Creates identity when needed, then signs [contentToSign] without mobile validation.
  ///
  /// Use this when your flow needs only the SDK signature payload and you will
  /// handle mobile validation in a different step/channel.
  Future<JustPaySdkResult> createIdentityAndSignOnly({
    required String challenge,
    required String contentToSign,
  }) async {
    if (_debugEnabled) {
      debugPrint(
        '[LankapayJustpayFlutter] createIdentityAndSignOnly called challengeLen=${challenge.length} contentToSignLen=${contentToSign.length}',
      );
    }
    Map<String, dynamic>? map;
    try {
      map = await _channel.invokeMapMethod<String, dynamic>(
        'createIdentityAndSignOnly',
        {
          'challenge': challenge,
          'contentToSign': contentToSign,
        },
      );
    } catch (e) {
      if (_debugEnabled) {
        debugPrint('[LankapayJustpayFlutter] createIdentityAndSignOnly failed with exception: $e');
      }
      rethrow;
    }

    if (map == null) {
      if (_debugEnabled) {
        debugPrint('[LankapayJustpayFlutter] createIdentityAndSignOnly returned null map');
      }
      if (_debugMocksEnabled) {
        if (_debugEnabled) {
          debugPrint('[LankapayJustpayFlutter] Debug mocks: simulating success from null map');
        }
        return _simulatedSuccessResult();
      }
      return const JustPaySdkResult(
        success: false,
        message: 'Empty SDK response',
      );
    }

    final result = JustPaySdkResult.fromMap(map);
    if (!result.success && _debugMocksEnabled) {
      if (_debugEnabled) {
        debugPrint(
          '[LankapayJustpayFlutter] Debug mocks: native returned success=false, simulating success',
        );
      }
      return _simulatedSuccessResult();
    }
    if (_debugEnabled) {
      final sig = result.signature;
      debugPrint(
        '[LankapayJustpayFlutter] createIdentityAndSignOnly result success=${result.success} messageLen=${result.message?.length ?? 0} signaturePresent=${sig != null && sig.isNotEmpty} signatureLen=${sig?.length ?? 0}',
      );
    }
    return result;
  }
}
