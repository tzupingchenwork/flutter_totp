import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:otp/otp.dart';
import 'dart:convert';
import 'package:ntp/ntp.dart';

class TotpProvider with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<String> codes = [];
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
    final allKeys = await storage.readAll();
    if (allKeys.isNotEmpty) {
      final currentTime = DateTime.now().millisecondsSinceEpoch + _timeOffset;
      codes = List<String>.from(allKeys.values.map((jsonStr) {
        if (jsonStr.startsWith('{')) {
          var map = jsonDecode(jsonStr);
          var secret = map['secret'];
          if (secret != null) {
            return OTP.generateTOTPCodeString(secret, currentTime,
                interval: 30,
                algorithm: Algorithm.SHA1,
                length: 6,
                isGoogle: true);
          }
        }
      }).where((code) => code != null));
      notifyListeners();
    }
  }

  Future<void> addCode(String key) async {
    await storage.write(key: key, value: key);
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
