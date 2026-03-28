import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lankapay_justpay_flutter/lankapay_justpay_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getDeviceId returns a string without throwing', (WidgetTester tester) async {
    final plugin = LankapayJustpayFlutter();
    final id = await plugin.getDeviceId();
    expect(id, isA<String>());
  });
}
