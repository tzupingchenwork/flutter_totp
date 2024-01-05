import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_totp/totp_provider.dart';
import 'package:provider/provider.dart';

class TotpListPage extends StatefulWidget {
  const TotpListPage({super.key});
  @override
  TotpListPageState createState() => TotpListPageState();
}

class TotpListPageState extends State<TotpListPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<String> keys = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer =
        Timer.periodic(const Duration(seconds: 30), (Timer t) => loadKeys());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadKeys() async {
    final allKeys = await storage.readAll();
    if (allKeys.isNotEmpty) {
      setState(() {
        keys = allKeys.values.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOTP List'),
      ),
      body: Consumer<TotpProvider>(builder: (context, totpProvider, child) {
        return ListView.builder(
          itemCount: totpProvider.codes.length,
          itemBuilder: (context, index) {
            String code = totpProvider.codes[index];
            double progress = totpProvider.remainingTime / 30; // 計算進度

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                title: Text(
                  'Code: $code',
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                trailing: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: progress, // 設置進度條進度
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    Text('${totpProvider.remainingTime}s'),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
