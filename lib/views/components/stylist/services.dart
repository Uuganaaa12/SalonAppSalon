import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_service_page.dart';
import 'service_detail_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  List<dynamic> services = [];
  bool loading = false;

  Future<void> fetchServices() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId = prefs.getString("stylistId");

    if (token == null || stylistId == null) return;

    final url = Uri.parse(
      "https://salonapp-l5y6.onrender.com/api/stylists/$stylistId/services",
    );
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      setState(() => services = jsonDecode(response.body));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Алдаа: ${response.body}")));
    }
  }

  Future<void> deleteService(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse(
      "https://salonapp-l5y6.onrender.com/api/stylists/services/$id",
    );

    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ $name устгагдлаа")));
      fetchServices();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Алдаа: ${response.body}")));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServicePage()),
          );
          if (result == true) fetchServices();
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  child: ListTile(
                    title: Text(service['service']['name']),
                    subtitle: Text(
                      "${service['price']}₮ • ${service['duration']} минут",
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailPage(service: service),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddServicePage(
                                  serviceId: service['_id'],
                                  serviceData: service,
                                ),
                              ),
                            );
                            if (result == true) fetchServices();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteService(
                            service['_id'],
                            service['service']['name'],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
