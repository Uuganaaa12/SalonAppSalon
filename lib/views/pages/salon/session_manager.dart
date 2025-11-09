import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';

class SessionManager {
  Timer? _logoutTimer;

  Future<User?> getUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );

    final exp = payload['exp'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (exp != null && now >= exp) {
      await logout();
      return null;
    }

    // Token-ийн хугацааг харгалзан таймер тавих
    _startAutoLogout(exp - now);

    return User(
      id: payload['userId'],
      name: payload['name'] ?? '',
      email: payload['email'] ?? '',
      role: payload['role'] ?? 'user',
    );
  }

  void _startAutoLogout(int secondsUntilExpiry) {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(Duration(seconds: secondsUntilExpiry), () async {
      await logout();
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _logoutTimer?.cancel();
  }
}
