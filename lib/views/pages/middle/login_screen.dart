import 'dart:convert';
import 'package:salon/data/notifiers.dart';
import 'package:salon/views/salon_widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salon/views/stylist_widget_tree.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPw = TextEditingController();
  bool isLoading = false;
  String _selectedRole = "salon";
  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPw.dispose();
    super.dispose();
  }

  Future<void> loginUser(String email, String password, String role) async {
    late Uri url;

    if (role == "salon") {
      url = Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/login");
    } else {
      url = Uri.parse(
        "https://salonapp-l5y6.onrender.com/api/stylists/stylist-login",
      );
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode != 200) {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final msg = body is Map && body["message"] != null
            ? body["message"]
            : 'Нэвтрэх амжилтгүй: ${response.statusCode}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final data = jsonDecode(response.body);
      String? token = data['token'];
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Token ирсэнгүй.")));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      if (role == "salon" && data["salon"] != null) {
        await prefs.setString("salonId", data["salon"]["_id"]);
        print("SalonId saved: ${data["salon"]["_id"]}");
      } else if (role == "stylist" && data["stylist"] != null) {
        await prefs.setString("stylistId", data["stylist"]["id"]);
        print("StylistId saved: ${data["stylist"]["id"]}");
      }
      Widget nextScreen = role == "salon"
          ? const SalonWidgetTree()
          : const StylistWidgetTree();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Сүлжээний алдаа: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void onLoginPressed() {
    final email = controllerEmail.text.trim();
    final password = controllerPw.text.trim();
    final role = _selectedRole;
    selectedPageNotifier.value = 0;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("И-мэйл, нууц үгээ оруулна уу")),
      );
      return;
    }
    loginUser(email, password, role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: "salon",
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const Text("Salon"),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: "stylist",
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const Text("Stylist"),
                ],
              ),
              TextField(
                controller: controllerEmail,
                decoration: const InputDecoration(
                  hintText: 'И-мэйл',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controllerPw,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Нууц үг',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // 👉 Role сонгох хэсэг
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : onLoginPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Нэвтрэх'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:salon/views/widget_tree.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key, required this.title});

//   final String title;

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController controllerEmail = TextEditingController();
//   final TextEditingController controllerPw = TextEditingController();
//   bool isLoading = false;

//   @override
//   void dispose() {
//     controllerEmail.dispose();
//     controllerPw.dispose();
//     super.dispose();
//   }

//   Future<void> loginUser(String email, String password) async {
//     final url = Uri.parse("https://salonapp-l5y6.onrender.com/api/auth/login");
//     setState(() => isLoading = true);

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"email": email, "password": password}),
//       );

//       if (response.statusCode != 200) {
//         final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
//         print(body);
//         final msg = body is Map && body["message"] != null
//             ? body["message"]
//             : 'Нэвтрэх амжилтгүй: ${response.statusCode}';
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(msg)));
//         return;
//       }

//       final data = jsonDecode(response.body);

//       // Төрөл бүрийн backend загварт зориулсан нөөц: token, accessToken, data.token гэх мэт
//       String? token = data is Map
//           ? (data['token'] ??
//                 data['accessToken'] ??
//                 (data['data'] is Map ? data['data']['token'] : null))
//           : null;

//       print("Login success, token(raw): $token");

//       if (token == null || token is! String || token.trim().isEmpty) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Token ирсэнгүй.")));
//         return;
//       }

//       // SharedPreferences дээр хадгалах — алдааг барина
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         final saved = await prefs.setString('token', token);
//         print("SharedPreferences setString returned: $saved");

//         if (!saved) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Token-г хадгалж чадсангүй.")),
//           );
//           return;
//         }
//       } catch (e) {
//         // Хэрвээ MissingPluginException эсвэл бусад алдаа байвал энд барина
//         print("SharedPreferences алдаа: $e");
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Хадгалах үед алдаа: $e")));
//         return;
//       }

//       // Амжилттай бол дараагийн дэлгэц рүү
//       if (!mounted) return;
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const WidgetTree()),
//         (route) => false,
//       );
//     } catch (e) {
//       print("Login request алдаа: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Сүлжээний алдаа: $e")));
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   void onLoginPressed() {
//     final email = controllerEmail.text.trim();
//     final password = controllerPw.text.trim();

//     if (email.isEmpty || password.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("И-мэйл, нууц үгээ оруулна уу")),
//       );
//       return;
//     }

//     loginUser(email, password);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.title)),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: controllerEmail,
//                 decoration: const InputDecoration(hintText: 'И-мэйл'),
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: controllerPw,
//                 obscureText: true,
//                 decoration: const InputDecoration(hintText: 'Нууц үг'),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton(
//                 onPressed: isLoading ? null : onLoginPressed,
//                 child: isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text('Нэвтрэх'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
