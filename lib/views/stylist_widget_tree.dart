import 'package:salon/data/notifiers.dart';
import 'package:salon/views/components/stylist/service_page.dart';
import 'package:salon/views/pages/stylist/dashboard/stylist_schedule_widget.dart';
import 'package:salon/views/pages/stylist/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:salon/views/pages/stylist/notification_screen.dart';
import 'package:salon/theme/app_colors.dart';
import 'package:salon/views/widgets/stylist/navbar_widget.dart';

// PageInfo class үүсгэх
class PageInfo {
  final String title;
  final Widget page;

  PageInfo({required this.title, required this.page});
}

// Хуудас болгоныг PageInfo-оор бүртгэх
final List<PageInfo> pageInfos = [
  PageInfo(title: "Stylist Dashboard", page: StylistScheduleWidget()),
  PageInfo(title: "Үйлчилгээ", page: ServicePage()),
  PageInfo(title: "Профайл", page: ProfilePage()),
];

class StylistWidgetTree extends StatelessWidget {
  const StylistWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, // Цагаан дэвсгэр
                    shape: BoxShape.circle, // Тойрог хэлбэр
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0), // Дотор зай
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
                const SizedBox(width: 8),
                // Сонгогдсон хуудасны title харуулах
                Text(
                  pageInfos[selectedPage].title,
                  style: TextStyle(color: AppColors.background),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return NotificationScreen(title: 'Мэдээлэл');
                      },
                    ),
                  );
                },
                icon: Icon(Icons.notifications, color: AppColors.background),
              ),
            ],
          ),
          body: pageInfos[selectedPage].page,
          bottomNavigationBar: StylistNavBarWidget(),
        );
      },
    );
  }
}
