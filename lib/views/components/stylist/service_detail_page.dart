import 'package:flutter/material.dart';

class ServiceDetailPage extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service['service']['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Үнэ: ${service['price']}₮",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Үргэлжлэх хугацаа: ${service['duration']} минут",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text("Статус: ${service['isActive'] ? "Идэвхтэй" : "Идэвхгүй"}"),
          ],
        ),
      ),
    );
  }
}
