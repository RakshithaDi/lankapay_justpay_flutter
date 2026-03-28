import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lankapay_justpay_flutter/lankapay_justpay_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Loading…';
  final _justPay = LankapayJustpayFlutter();

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      final id = await _justPay.getDeviceId();
      if (!mounted) return;
      setState(() {
        _status = id.isEmpty
            ? 'Empty device id (add LPTrusted SDK + config; see plugin README).'
            : 'Device id: $id';
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Platform error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('JustPay plugin example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_status, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
