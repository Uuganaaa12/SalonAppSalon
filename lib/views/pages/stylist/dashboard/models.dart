import 'package:intl/intl.dart';

class TimeSlot {
  String time;
  bool isAvailable;
  String? id;
  Booking? booking;

  TimeSlot({
    required this.time,
    required this.isAvailable,
    this.id,
    this.booking,
  });
}

class Booking {
  final String id;
  final String customerName;
  final String serviceName;
  final String timeSlot;
  final String status;
  final double finalPrice;
  final String notes;
  final DateTime date;

  Booking({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.timeSlot,
    required this.status,
    required this.finalPrice,
    required this.notes,
    required this.date,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      return Booking(
        id: json['_id']?.toString() ?? '',
        customerName: _extractCustomerName(json['customer']),
        serviceName: _extractServiceName(json['service']),
        timeSlot: json['timeSlot']?.toString() ?? '',
        status: json['status']?.toString() ?? 'confirmed',
        finalPrice: _parseDouble(json['finalPrice'] ?? json['totalPrice'] ?? 0),
        notes: json['notes']?.toString() ?? '',
        date: _parseDate(json['date']),
      );
    } catch (e) {
      print('Error parsing booking JSON: $e');
      print('JSON data: $json');
      return Booking(
        id: '',
        customerName: 'Алдаа гарсан',
        serviceName: '',
        timeSlot: '',
        status: 'confirmed',
        finalPrice: 0.0,
        notes: '',
        date: DateTime.now(),
      );
    }
  }

  static String _extractCustomerName(dynamic customer) {
    if (customer == null) return 'Тодорхойгүй';
    if (customer is String) return customer;
    if (customer is Map<String, dynamic>) {
      return customer['name']?.toString() ?? 'Тодорхойгүй';
    }
    return 'Тодорхойгүй';
  }

  static String _extractServiceName(dynamic service) {
    if (service == null) return '';
    if (service is String) return service;
    if (service is Map<String, dynamic>) {
      return service['name']?.toString() ?? '';
    }
    return '';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parsing date: $dateValue');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
