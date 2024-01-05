import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:otp/otp.dart';

class TotpProvider with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<String> codes = [];

  TotpProvider() {
    loadCodes();
  }

  Future<void> loadCodes() async {
    final allKeys = await storage.readAll();
    if (allKeys.isNotEmpty) {
      codes = allKeys.values.map((key) {
        return OTP.generateTOTPCodeString(
            key, DateTime.now().millisecondsSinceEpoch,
            interval: 30, algorithm: Algorithm.SHA1, length: 6);
      }).toList();
      notifyListeners();
    }
  }
}
