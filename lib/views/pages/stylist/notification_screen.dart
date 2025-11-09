import 'package:flutter/material.dart';
import 'package:salon/theme/app_colors.dart';
import 'package:salon/views/pages/salon/expanded_flexible_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.title});

  final String title;
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  TextEditingController controller = TextEditingController();
  bool? isChecked = false;
  bool isSwitched = false;
  double sliderValue = 0.0;
  String? menuItem = 'e1';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.primary,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
          color: AppColors.textLight,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(100),
          child: Text(
            "stylist notification",
            style: TextStyle(color: AppColors.primary, fontSize: 30),
          ),
        ),
      ),
    );
  }
}
//1:45:00 end