import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:salon/views/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salon/views/pages/middle/login_screen.dart';
import 'package:salon/views/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  User? user;

  if (token != null) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );

        // Role тодорхойлох
        String role = '';
        String? id;
        if (payload['salonId'] != null) {
          role = 'salon';
          id = payload['salonId'];
        } else if (payload['stylistId'] != null) {
          role = 'stylist';
          id = payload['stylistId'];
        } else {
          role = 'user';
        }

        user = User(id: id ?? '', name: '', email: '', role: role);
      }
    } catch (e) {
      print("❌ Token decode алдаа: $e");
      user = null;
    }
  }

  runApp(MyApp(user: user));
}

class MyApp extends StatefulWidget {
  final User? user;
  const MyApp({super.key, this.user});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _logoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _startLogoutTimer();
    } else if (state == AppLifecycleState.resumed) {
      print("🟢 App буцаж ирлээ, таймер цуцлагдлаа");
      _logoutTimer?.cancel();
    }
  }

  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    print("⏱ Logout timer эхэллээ (background-д 2 минут)");
    _logoutTimer = Timer(const Duration(minutes: 2), () async {
      print("⏳ 2 минут өнгөрлөө, автомат logout хийж байна...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Таны сесс дууссан. Дахин нэвтэрнэ үү."),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage(title: "Нэвтрэх")),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: AppRoutes.getHome(widget.user),
    );
  }
}
