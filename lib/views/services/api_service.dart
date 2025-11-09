// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   final String baseUrl = "https://salonapp-l5y6.onrender.com/api";

//   Future<dynamic> login(String email, String password) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/users/login"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"email": email, "password": password}),
//     );
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body);
//     } else {
//       throw Exception("Login failed");
//     }
//   }

//   Future<List<dynamic>> getSalons() async {
//     final res = await http.get(Uri.parse("$baseUrl/salons"));
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body);
//     } else {
//       throw Exception("Failed to fetch salons");
//     }
//   }
// }

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:salon/views/models/salon.dart';

Future<void> registerUser(String name, String email, String password) async {
  final res = await http.post(
    Uri.parse('https://salonapp-l5y6.onrender.com/api/users/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name, 'email': email, 'password': password}),
  );

  if (res.statusCode != 201) {
    throw Exception('Failed to register: ${res.body}');
  }
}

Future<Salon?> fetchSalonById(String id, String token) async {
  final url = Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/$id");

  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return Salon.fromJson(data);
  } else {
    throw Exception("Салоны мэдээлэл авахад алдаа гарлаа");
  }
}
