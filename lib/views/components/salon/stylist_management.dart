import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('https://salonapp-l5y6.onrender.com/api/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          users = data.map((e) => User.fromJson(e)).toList();
          loading = false;
        });
      } else {
        print("❌ Failed to fetch users: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("⚠️ Exception: $e");
    }
  }

  Future<void> deleteUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final res = await http.delete(
      Uri.parse('https://salonapp-l5y6.onrender.com/api/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 👈 токен нэмсэн
      },
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User deleted"),
          backgroundColor: Colors.red,
        ),
      );
      fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete user: ${res.body}")),
      );
    }
  }

  // Future<void> updateUser(String id, String name, String email) async {
  //   final res = await http.put(
  //     Uri.parse('https://salonapp-l5y6.onrender.com/api/users/$id'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'name': name, 'email': email}),
  //   );

  //   if (res.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("User updated"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //     fetchUsers();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Failed to update user: ${res.body}")),
  //     );
  //   }
  // }

  void showEditDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     updateUser(user.id, nameController.text, emailController.text);
          //     Navigator.pop(context);
          //   },
          //   child: const Text("Save"),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users List")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showEditDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(user.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
