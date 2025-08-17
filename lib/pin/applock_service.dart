import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppLockService  {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static bool _phnisUnlocked = false;
  static bool phoneisUnlocked(){
    return _phnisUnlocked;
  }
  static bool setPhoneUnlocked(bool value){
    return _phnisUnlocked = value;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_pin');
  }

  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('app_pin');
  }

  static Future<void> setHintQuestion(String question) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hint_question', question);
  }

  static Future<String?> getHintQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hint_question');
  }
  static Future<void> setHintQuestion2(String question2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hint_question2', question2);
  }
  static Future<String?> getHintQuestion2() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hint_question2');
  }

  static Future<void> setHintAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hint_answer', answer);
  }

  static Future<String?> getHintAnswer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hint_answer');
  }

  static Future<void> setHintAnswer2(String answer2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hint_answer2', answer2);
  }

  static Future<String?> getHintAnswer2() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('hint_answer2');
  }

  static Future<bool> validatePin(String enteredPin) async {
    final storedPin = await getPin();
    return storedPin == enteredPin;
  }

  static Future<bool> removePin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('app_pin');

    if (storedPin == enteredPin) {
      await prefs.remove('app_pin');
      await prefs.remove('hint_question');
      await prefs.remove('hint_answer');
      await prefs.remove('hint_question2');
      await prefs.remove('hint_answer2');
      return true;
    }
    return false;
  }

  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print("Biometric check error: $e");
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print("Error getting biometrics: $e");
      return <BiometricType>[];
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          // biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print("PlatformException: ${e.message}");
      return false;
    } catch (e) {
      print("Biometric auth error: $e");
      return false;
    }
  }
}
