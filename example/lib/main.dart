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
  String _identityStatus = '';
  final _justPay = LankapayJustpayFlutter();

  final _challengeController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _challengeController.dispose();
    _contentController.dispose();
    super.dispose();
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

  Future<void> _createIdentityAndSign() async {
    final challenge = _challengeController.text.trim();
    final contentToSign = _contentController.text.trim();

    if (challenge.isEmpty || contentToSign.isEmpty) {
      setState(() => _identityStatus = 'Please fill challenge and contentToSign');
      return;
    }

    try {
      setState(() => _identityStatus = 'Calling createIdentityAndSign…');
      final result = await _justPay.createIdentityAndSign(
        challenge: challenge,
        contentToSign: contentToSign,
      );

      final sig = result.signature;
      final token = result.mobileReference;

      setState(() {
        if (result.success) {
          _identityStatus =
              'createIdentityAndSign success. message=${result.message ?? 'OK'} signatureLen=${sig?.length ?? 0} mobileReferenceLen=${token?.length ?? 0}';
        } else {
          _identityStatus =
              'createIdentityAndSign failed. message=${result.message ?? 'Error'}';
        }
      });
    } on PlatformException catch (e) {
      setState(() => _identityStatus = 'Platform error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('JustPay plugin example')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _challengeController,
                  decoration: const InputDecoration(
                    labelText: 'challenge (from bank API)',
                    hintText: 'Paste challenge string here',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'contentToSign (terms text)',
                    hintText: 'Paste text that user agreed to',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createIdentityAndSign,
                  child: const Text('createIdentityAndSign'),
                ),
                const SizedBox(height: 16),
                Text(
                  _identityStatus,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
