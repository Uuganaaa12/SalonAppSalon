import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddServicePage extends StatefulWidget {
  final String? serviceId;
  final Map<String, dynamic>? serviceData;

  const AddServicePage({super.key, this.serviceId, this.serviceData});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final priceController = TextEditingController();
  final durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.serviceData != null) {
      priceController.text = widget.serviceData!['price'].toString();
      durationController.text = widget.serviceData!['duration'].toString();
    }
  }

  Future<void> saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId = prefs.getString("stylistId");

    if (token == null || stylistId == null) return;

    final url = widget.serviceId == null
        ? Uri.parse("https://salonapp-l5y6.onrender.com/api/stylists/services")
        : Uri.parse(
            "https://salonapp-l5y6.onrender.com/api/stylists/services/${widget.serviceId}",
          );

    final body = jsonEncode({
      "stylistId": stylistId,
      "serviceId":
          widget.serviceData?['service']?['_id'] ?? "650f9c2c1c9d440000a1b3f0",
      "price": int.parse(priceController.text),
      "duration": int.parse(durationController.text),
    });

    final response = await (widget.serviceId == null
        ? http.post(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: body,
          )
        : http.put(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: body,
          ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Алдаа: ${response.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.serviceId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Засах" : "Нэмэх")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Үнэ"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Үнэ оруулна уу" : null,
              ),
              TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Үргэлжлэх хугацаа (мин)",
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Хугацаа оруулна уу" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveService,
                child: Text(isEdit ? "Засах" : "Нэмэх"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
