import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:otp/otp.dart';
import 'dart:convert';
import 'package:ntp/ntp.dart';

class TotpProvider with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> jsonList = [];
  Timer? timer;
  Timer? _secondTimer;
  int remainingTime = 30;

  TotpProvider() {
    loadCodes();
    startTimer();
    _startSecondTimer();
  }

  void startTimer() {
    final now = DateTime.now();
    final secondsUntilNextRefresh = 30 - now.second % 30;

    Timer(Duration(seconds: secondsUntilNextRefresh), () {
      loadCodes();
      timer =
          Timer.periodic(const Duration(seconds: 30), (Timer t) => loadCodes());
    });
  }

  void _startSecondTimer() {
    _secondTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => updateRemainingTime());
  }

  void updateRemainingTime() {
    final now = DateTime.now();
    remainingTime = 30 - now.second % 30;
    notifyListeners();
  }

  int _timeOffset = 0;

  Future<void> syncTimeWithServer() async {
    try {
      final DateTime ntpTime = await NTP.now();
      _timeOffset = ntpTime.millisecondsSinceEpoch -
          DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadCodes() async {
    await syncTimeWithServer();
    final allKeys = await storage.readAll();
    jsonList.clear(); // 清空列表以便重新填充
    if (allKeys.isNotEmpty) {
      for (var jsonStr in allKeys.values) {
        if (jsonStr.startsWith('{')) {
          var map = jsonDecode(jsonStr);
          var secret = map['secret'];
          var type = map['type'];
          var label = map['label'];
          var issuer = map['issuer'];
          if (secret != null) {
            jsonList.add({
              'type': type,
              'label': label,
              'secret': secret,
              'issuer': issuer,
              'code': OTP.generateTOTPCodeString(
                  secret, DateTime.now().millisecondsSinceEpoch + _timeOffset,
                  interval: 30,
                  algorithm: Algorithm.SHA1,
                  length: 6,
                  isGoogle: true)
            });
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> addCode(String name, String secret, String issuer) async {
    String key = 'totpKey_${DateTime.now().millisecondsSinceEpoch}';
    String value = jsonEncode(
        {'type': 'otp', 'label': name, 'secret': secret, 'issuer': issuer});

    print(name);
    print(secret);
    // Store the JSON object
    await storage.write(key: key, value: value);
    // Reload the codes and notify listeners
    await loadCodes();
    notifyListeners();
  }

  Future<void> removeCode(String key) async {
    await storage.delete(key: key);
    await loadCodes();
    notifyListeners();
  }

  Future<void> removeAllCodes() async {
    await storage.deleteAll();
    await loadCodes();
    notifyListeners();
  }

  @override
  void dispose() {
    timer?.cancel();
    _secondTimer?.cancel();
    super.dispose();
  }
}
