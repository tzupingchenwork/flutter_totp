import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_totp/totp_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  final storage = const FlutterSecureStorage();

  @override
  // ignore: library_private_types_in_public_api
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Consumer<TotpProvider>(builder: (context, totpProvider, child) {
        return Column(
          children: <Widget>[
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ],
        );
      }),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();

      // Parse the OTPAUTH URI
      var uri = Uri.parse(scanData.code!);
      var type = uri.scheme;
      var label = uri.pathSegments[0];
      var secret = uri.queryParameters['secret'];
      var issuer = uri.queryParameters['issuer'];

      // Store the secret and issuer
      String key = 'totpKey_${DateTime.now().millisecondsSinceEpoch}';
      String value = jsonEncode(
          {'type': type, 'label': label, 'secret': secret, 'issuer': issuer});
      await widget.storage.write(key: key, value: value);

      // Show a snack bar
      var context = this.context; // Store the BuildContext in a variable
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'QR Code scanned successfully! Secret: $secret, Issuer: $issuer'),
        ),
      );

      // Load codes immediately after scanning
      // ignore: use_build_context_synchronously
      var totpProvider = Provider.of<TotpProvider>(context, listen: false);
      await totpProvider.loadCodes();

      // Wait for one second and then navigate to the list page
      Future.delayed(const Duration(seconds: 1)).then((_) {
        Navigator.pushNamed(context, '/list');
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
