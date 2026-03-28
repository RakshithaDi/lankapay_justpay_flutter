/// Result of a native JustPay / LPTrusted SDK operation from the method channel.
class JustPaySdkResult {
  final bool success;
  final String? message;
  final String? signature;
  final String? mobileReference;

  const JustPaySdkResult({
    required this.success,
    this.message,
    this.signature,
    this.mobileReference,
  });

  factory JustPaySdkResult.fromMap(Map<String, dynamic> map) {
    return JustPaySdkResult(
      success: map['success'] == true,
      message: map['message'] as String?,
      signature: map['signature'] as String?,
      mobileReference: map['mobileReference'] as String?,
    );
  }
}
