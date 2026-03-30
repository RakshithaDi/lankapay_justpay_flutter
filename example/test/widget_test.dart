// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lankapay_justpay_flutter_example/main.dart';

void main() {
  testWidgets('Verify Platform version', (WidgetTester tester) async {
    const MethodChannel channel = MethodChannel('justpay_sdk/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getDeviceId':
          return 'test-device-id';
        case 'createIdentityAndSign':
          return <String, dynamic>{
            'success': true,
            'message': 'OK',
            'signature': 'sig',
            'mobileReference': 'mref',
          };
        default:
          return null;
      }
    });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that platform version is retrieved.
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Text &&
                           widget.data == 'Device id: test-device-id',
      ),
      findsOneWidget,
    );
  });
}
