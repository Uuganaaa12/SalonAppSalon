import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_stylist_page.dart';
import 'stylist_detail_page.dart';

class StylistListPage extends StatefulWidget {
  const StylistListPage({super.key});

  @override
  State<StylistListPage> createState() => _StylistListPageState();
}

class _StylistListPageState extends State<StylistListPage> {
  List<dynamic> stylists = [];
  bool loading = false;

  Future<void> fetchStylists() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    if (token == null || salonId == null) return;

    final url = Uri.parse(
      "https://salonapp-l5y6.onrender.com/api/stylists/salon/$salonId",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      setState(() {
        stylists = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Алдаа: ${response.body}")));
    }
  }

  Future<void> deleteStylist(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse(
      "https://salonapp-l5y6.onrender.com/api/stylists/$id",
    );
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ $name амжилттай устгагдлаа")));
      fetchStylists();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Устгах амжилтгүй: ${response.body}")),
      );
    }
  }

  Future<void> _showDeleteConfirmation(String id, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text(
          //   "⚠️ Анхааруулга",
          //   style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          // ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(text: "Та "),
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: " стилистийг устгахдаа итгэлтэй байна уу?",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Цуцлах",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Устгах",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      deleteStylist(id, name);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStylistPage()),
          );
          if (result == true) fetchStylists();
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(top: 20.0), // жагсаалтын дээр зай
              child: ListView.builder(
                itemCount: stylists.length,
                itemBuilder: (context, index) {
                  final stylist = stylists[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            (stylist['photo'] is String &&
                                (stylist['photo'] as String).isNotEmpty)
                            ? NetworkImage(stylist['photo'] as String)
                            : const AssetImage("assets/images/bgImage.jpg"),
                      ),
                      title: Text(stylist['name']),
                      subtitle: Text(" ${stylist['email']}"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StylistDetailPage(stylist: stylist),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddStylistPage(
                                    stylistId: stylist['_id'],
                                    stylistData: stylist,
                                  ),
                                ),
                              );
                              if (result == true) fetchStylists();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(
                              stylist['_id'],
                              stylist['name'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
