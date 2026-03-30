import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lankapay_justpay_flutter/lankapay_justpay_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('justpay_sdk/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getDeviceId':
          return 'test-device-id';
        case 'createIdentityAndSign':
          return {
            'success': true,
            'message': 'OK',
            'signature': 'sig',
            'mobileReference': 'mref',
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getDeviceId forwards channel result', () async {
    final plugin = LankapayJustpayFlutter();
    expect(await plugin.getDeviceId(), 'test-device-id');
  });

  test('createIdentityAndSign maps response to JustPaySdkResult', () async {
    final plugin = LankapayJustpayFlutter();
    final r = await plugin.createIdentityAndSign(
      challenge: 'c',
      contentToSign: 'body',
    );
    expect(r.success, true);
    expect(r.signature, 'sig');
    expect(r.mobileReference, 'mref');
  });

  test('debug mocks: simulate success when native returns success=false',
      () async {
    // Override the mock handler for this test only.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getDeviceId':
          return 'test-device-id';
        case 'createIdentityAndSign':
          return {
            'success': false,
            'message': 'native failure',
            'signature': '',
            'mobileReference': '',
          };
        default:
          return null;
      }
    });

    final plugin = LankapayJustpayFlutter(enableDebugMocks: true);
    final r = await plugin.createIdentityAndSign(
      challenge: 'c',
      contentToSign: 'body',
    );

    expect(r.success, true);
    expect(r.signature, isNotEmpty);
    expect(r.mobileReference, isNotEmpty);

    // Restore the default setUp handler for remaining tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getDeviceId':
          return 'test-device-id';
        case 'createIdentityAndSign':
          return {
            'success': true,
            'message': 'OK',
            'signature': 'sig',
            'mobileReference': 'mref',
          };
        default:
          return null;
      }
    });
  });
}
