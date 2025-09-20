
import 'package:shared_preferences/shared_preferences.dart';

class GestureService{

  static Future<void> setGestureEnable(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGestureEnable', value);
  }

  static Future<bool> getGestureEnable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGestureEnable') ?? false;
  }
}