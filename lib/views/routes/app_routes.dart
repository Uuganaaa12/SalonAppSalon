import 'package:salon/views/pages/middle/login_screen.dart';
import 'package:salon/views/salon_widget_tree.dart';
import 'package:salon/views/stylist_widget_tree.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class AppRoutes {
  static Widget getHome(User? user) {
    if (user == null) return const LoginPage(title: "Нэвтрэх");

    switch (user.role) {
      case 'salon':
        return const SalonWidgetTree();
      case 'stylist':
        return const StylistWidgetTree();
      default:
        return const LoginPage(title: "Нэвтрэх");
    }
  }
}
