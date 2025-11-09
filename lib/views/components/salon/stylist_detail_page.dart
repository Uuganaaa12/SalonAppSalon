import 'package:flutter/material.dart';

class StylistDetailPage extends StatelessWidget {
  final Map<String, dynamic> stylist;
  const StylistDetailPage({super.key, required this.stylist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stylist['name'] ?? "Стилист"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (stylist['photo'] != null &&
                stylist['photo'].toString().isNotEmpty)
              // Image.network(stylist['photo'], height: 200, fit: BoxFit.cover),
              Image.network(stylist['photo'], height: 200),
            const SizedBox(height: 20),
            Text(
              "👤 Нэр: ${stylist['name']}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "📧 Имэйл: ${stylist['email']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "📞 Утас: ${stylist['phone'] ?? '---'}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "🧑‍💼 Туршлага: ${stylist['experience'] ?? 0} жил",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "⭐ Үнэлгээ: ${stylist['rating'] ?? 0}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "💬 Танилцуулга: ${stylist['bio'] ?? '---'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "🏷️ Чиглэлүүд: ${(stylist['specialties'] as List?)?.join(', ') ?? '---'}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
