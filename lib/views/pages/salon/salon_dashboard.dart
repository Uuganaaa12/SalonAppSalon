import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salon/theme/app_colors.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SalonDashboard extends StatefulWidget {
  const SalonDashboard({super.key});

  @override
  State<SalonDashboard> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<SalonDashboard> {
  int totalStylists = 0;
  int totalCustomers = 0;
  int totalServices = 0;
  double rating = 0.0;

  Map<String, dynamic> workingHours = {};

  @override
  void initState() {
    super.initState();
    fetchSalonStats();
  }

  Future<void> fetchSalonStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");
    final res = await http.get(
      Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/$salonId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        totalStylists = data['stylists']?.length ?? 0;
        totalCustomers = data['customers']?.length ?? 0;
        totalServices = data['services']?.length ?? 0;
        rating = (data['rating'] ?? 0).toDouble();
        workingHours = Map<String, dynamic>.from(data['workingHours'] ?? {});
      });
    }
  }

  Future<void> updateWorkingHours() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    final res = await http.put(
      Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/$salonId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"workingHours": workingHours}),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Цагийн хуваарь шинэчлэгдлээ!")),
      );
    }
  }

  Future<void> pickTime(String day, String field) async {
    final current = workingHours[day]?[field] ?? "09:00";
    final parts = current.split(":");
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        workingHours[day]?[field] =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---- Top Stats ----
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                children: [
                  _StatCard(title: "Нийт стилист", value: "$totalStylists"),
                  // _StatCard(
                  //   title: "Нийт үйлчлүүлэгч",
                  //   value: "$totalCustomers",
                  // ),
                  _StatCard(title: "Нийт үйлчилгээ", value: "14"),
                  // _StatCard(
                  //   title: "Rating дундаж",
                  //   value: rating.toStringAsFixed(1),
                  // ),
                ],
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        "Дундаж үнэлгээ: ",
                        style: TextStyle(fontSize: 14.0),
                      ),
                      Text(
                        "4.5",
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Цагийн хуваарь",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...workingHours.keys.map((day) {
                        final dayData = workingHours[day];
                        // Convert day name to Mongolian
                        final Map<String, String> dayNames = {
                          'monday': 'Даваа',
                          'tuesday': 'Мягмар',
                          'wednesday': 'Лхагва',
                          'thursday': 'Пүрэв',
                          'friday': 'Баасан',
                          'saturday': 'Бямба',
                          'sunday': 'Ням',
                        };

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              // Day name (allow ellipsis on very narrow screens)
                              SizedBox(
                                width: 60,
                                child: Text(
                                  dayNames[day] ??
                                      (day[0].toUpperCase() + day.substring(1)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              // Status switch (constrained to avoid overflow)
                              SizedBox(
                                width: 48,
                                child: Switch(
                                  value: dayData['isOpen'] ?? false,
                                  onChanged: (val) {
                                    setState(() {
                                      workingHours[day]['isOpen'] = val;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Time buttons (only show if day is open)
                              if (dayData['isOpen'] ?? false) ...[
                                Expanded(
                                  child: Row(
                                    children: [
                                      // Open time
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => pickTime(day, "open"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.blue[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.blue[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dayData['open'] ?? '09:00',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: SizedBox(
                                          width: 14,
                                          child: Center(
                                            child: Text(
                                              '→',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Close time
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => pickTime(day, "close"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.orange[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.orange[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dayData['close'] ?? '18:00',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.orange[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Expanded(
                                  child: Text(
                                    'Хаалттай',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: updateWorkingHours,
                child: const Text("Хадгалах"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
