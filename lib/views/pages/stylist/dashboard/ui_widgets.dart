import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'schedule_service.dart';

class UIWidgets {
  static Widget buildStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  static Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static Widget buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Захиалсан';
      case 'cancelled':
        return 'Цуцлагдсан';
      case 'completed':
        return 'Дууссан';
      case 'no_show':
        return 'Ирээгүй';
      default:
        return status;
    }
  }

  static Map<String, dynamic> getSlotStyle(TimeSlot slot) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String status;

    if (slot.booking != null) {
      final bookingStatus = slot.booking!.status;
      switch (bookingStatus) {
        case 'confirmed':
          cardColor = const Color(0xFFDEEAFE);
          textColor = const Color(0xFF2563EB);
          icon = Icons.check_circle;
          status = 'Захиалсан';
          break;
        case 'completed':
          cardColor = const Color(0xFFECFDF5);
          textColor = const Color(0xFF059669);
          icon = Icons.check_circle_outline;
          status = 'Дууссан';
          break;
        case 'cancelled':
          cardColor = const Color(0xFFFEE2E2);
          textColor = const Color(0xFFDC2626);
          icon = Icons.cancel_outlined;
          status = 'Цуцлагдсан';
          break;
        case 'no_show':
          cardColor = const Color(0xFFF3F4F6);
          textColor = const Color(0xFF6B7280);
          icon = Icons.person_off;
          status = 'Ирээгүй';
          break;
        default:
          cardColor = const Color(0xFFDEEAFE);
          textColor = const Color(0xFF2563EB);
          icon = Icons.person;
          status = 'Захиалсан';
      }
    } else if (slot.isAvailable) {
      cardColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF059669);
      icon = Icons.check_circle;
      status = 'Боломжтой';
    } else {
      cardColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.cancel;
      status = 'Хаалттай';
    }

    return {
      'cardColor': cardColor,
      'textColor': textColor,
      'icon': icon,
      'status': status,
    };
  }
}
