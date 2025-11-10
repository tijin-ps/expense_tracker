import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String _emailkey = "email";
  static String _mobilekey = "mobile";
  static String _budgetKey = "budget";
  static String _isloginkey = "isLogin";

  Future<void> saveusercredentials({
    required String email,
    required String mobile,
  }) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString(_emailkey, email);
    pref.setString(_mobilekey, mobile);
    pref.setBool(_isloginkey, true);
  }

  Future<String?> getemail() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.containsKey(_emailkey)) {
      return pref.getString(_emailkey);
    }
    return null;
  }

  Future<String?> getphone() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.containsKey(_mobilekey)) {
      return pref.getString(_mobilekey);
    }
    return null;
  }

  Future<bool?> islogin() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.containsKey(_isloginkey)) {
      return pref.getBool(_isloginkey);
    } else {
      return false;
    }
  }

  Future<String?> getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("imagePath");
  }

  Future<void> saveBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, budget);
  }

  Future<bool> isBudgetSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_budgetKey);
  }

  Future<void> logout() async {
    final pref = await SharedPreferences.getInstance();
    pref.remove(_isloginkey);
    pref.remove(_emailkey);
    pref.remove(_mobilekey);
    pref.remove(_budgetKey);
    pref.clear();
  }
}
