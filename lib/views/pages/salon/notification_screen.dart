import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salon/theme/app_colors.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.title});
  final String title;
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationItem> _items = [];
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _page++;
        _fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    setState(() => _loading = true);
    if (refresh) {
      _page = 1;
      _items.clear();
      _hasMore = true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() => _loading = false);
        return;
      }
      final uri = Uri.parse(
        'https://salonapp-l5y6.onrender.com/api/notifications?page=$_page&limit=20',
      );
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['items'] ?? [];
        final newItems = list.map((e) => NotificationItem.fromJson(e)).toList();
        setState(() {
          _items.addAll(newItems);
          final int pages = data['pages'] ?? _page;
          _hasMore = _page < pages;
        });
      } else {
        // error can be shown
      }
    } catch (e) {
      // log error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final uri = Uri.parse(
      'https://salonapp-l5y6.onrender.com/api/notifications/$id/read',
    );
    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      setState(() {
        final idx = _items.indexWhere((n) => n.id == id);
        if (idx != -1) {
          _items[idx] = NotificationItem(
            id: _items[idx].id,
            title: _items[idx].title,
            message: _items[idx].message,
            type: _items[idx].type,
            isRead: true,
            createdAt: _items[idx].createdAt,
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final uri = Uri.parse(
      'https://salonapp-l5y6.onrender.com/api/notifications/mark-all-read',
    );
    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = NotificationItem(
            id: _items[i].id,
            title: _items[i].title,
            message: _items[i].message,
            type: _items[i].type,
            isRead: true,
            createdAt: _items[i].createdAt,
          );
        }
      });
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Colors.green.shade100;
      case 'booking_cancelled':
        return Colors.red.shade100;
      case 'booking_reminder':
        return Colors.orange.shade100;
      case 'new_booking':
        return Colors.blue.shade100;
      case 'payment_received':
        return Colors.teal.shade100;
      case 'rating_received':
        return Colors.purple.shade100;
      case 'promotion':
        return Colors.pink.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.primary,
        leading: BackButton(color: AppColors.textLight),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _fetchNotifications(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _items.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),

      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchNotifications(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final n = _items[index];
                  return Card(
                    color: _typeColor(n.type),
                    elevation: n.isRead ? 0 : 2,
                    child: ListTile(
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.message),
                      const SizedBox(height: 4),
                      Text(
                        '${n.createdAt.toLocal()}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: n.isRead
                      ? const Icon(Icons.check, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: () => _markAsRead(n.id),
                        ),
                  ),
                  );
                },
              ),
            ),
    );
  }
}
