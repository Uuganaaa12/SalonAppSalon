import 'package:salon/data/notifiers.dart';
import 'package:salon/views/pages/salon/salon_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:salon/views/pages/salon/profile_screen.dart';
import 'package:salon/views/pages/salon/notification_screen.dart';
import 'package:salon/views/components/salon/stylists.dart';
import 'package:salon/theme/app_colors.dart';
import 'widgets/salon/navbar_widget.dart';

class PageInfo {
  final String title;
  final Widget page;

  PageInfo({required this.title, required this.page});
}

final List<PageInfo> pageInfos = [
  PageInfo(title: "Salon Dashboard", page: SalonDashboard()),
  PageInfo(title: "Stylists", page: StylistListPage()),
  PageInfo(title: "Profile", page: ProfilePage()),
];

class SalonWidgetTree extends StatelessWidget {
  const SalonWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final currentPageInfo = pageInfos[selectedPage];

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
                Text(
                  currentPageInfo.title,
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
          body: currentPageInfo.page,
          bottomNavigationBar: SalonNavBarWidget(),
        );
      },
    );
  }
}
