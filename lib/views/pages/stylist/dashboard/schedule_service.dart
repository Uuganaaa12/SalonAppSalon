import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class ScheduleService {
  static const String baseUrl = 'https://salonapp-l5y6.onrender.com/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<String?> getStylistId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("stylistId");
  }

  static Future<List<TimeSlot>> fetchAvailableSlots(
    String stylistId,
    DateTime date,
  ) async {
    final token = await _getToken();
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/schedule/available/$stylistId/$dateString"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final slotsData = data['availableSlots'] as List?;
          return (slotsData ?? [])
              .map((slot) {
                if (slot is Map<String, dynamic>) {
                  return TimeSlot(
                    time: slot['time']?.toString() ?? '',
                    isAvailable: slot['isAvailable'] == true,
                  );
                }
                return null;
              })
              .where((slot) => slot != null)
              .cast<TimeSlot>()
              .toList();
        }
      } else if (response.statusCode == 404) {
        return await _fetchStylistSchedule(stylistId, date);
      }
    } catch (e) {
      print("Error fetching available slots: $e");
      return await _fetchStylistSchedule(stylistId, date);
    }
    return [];
  }

  static Future<List<TimeSlot>> _fetchStylistSchedule(
    String stylistId,
    DateTime date,
  ) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/stylists/$stylistId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final schedule = data['schedule'] as List?;
        final dayName = _getDayName(date);

        if (schedule != null) {
          final daySchedule = schedule.firstWhere(
            (day) => day is Map<String, dynamic> && day['day'] == dayName,
            orElse: () => null,
          );

          if (daySchedule != null && daySchedule is Map<String, dynamic>) {
            final slots = daySchedule['slots'] as List?;
            return (slots ?? [])
                .map((slot) {
                  if (slot is Map<String, dynamic>) {
                    return TimeSlot(
                      time: slot['time']?.toString() ?? '',
                      isAvailable: slot['isAvailable'] == true,
                    );
                  }
                  return null;
                })
                .where((slot) => slot != null)
                .cast<TimeSlot>()
                .toList();
          }
        }
      }
    } catch (e) {
      print("Error fetching stylist schedule: $e");
    }
    return [];
  }

  static Future<List<Booking>> fetchBookings(
    String stylistId,
    DateTime date,
  ) async {
    final token = await _getToken();
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final selectedDateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/stylist/$stylistId?date=$dateString"),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> bookingsData = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData['bookings'] != null) {
            bookingsData = responseData['bookings'] as List;
            print("booking data: $bookingsData");
          }
        } else if (responseData is List) {
          bookingsData = responseData;
        }

        return bookingsData
            .map((booking) {
              try {
                if (booking is Map<String, dynamic>) {
                  final bookingObj = Booking.fromJson(booking);
                  final bookingDateString = DateFormat(
                    'yyyy-MM-dd',
                  ).format(bookingObj.date);

                  if (bookingDateString == selectedDateString &&
                      bookingObj.status != 'cancelled' &&
                      bookingObj.status != 'no_show') {
                    return bookingObj;
                  }
                }
                return null;
              } catch (e) {
                print("Error parsing booking: $e");
                return null;
              }
            })
            .where((booking) => booking != null)
            .cast<Booking>()
            .toList();
      }
    } catch (e) {
      print("Error fetching bookings: $e");
    }
    return [];
  }

  static Future<bool> toggleSlotAvailability(
    String stylistId,
    TimeSlot slot,
    DateTime date,
  ) async {
    final token = await _getToken();
    final dayName = _getDayName(date);

    final requestData = {
      'day': dayName,
      'time': slot.time,
      'isAvailable': !slot.isAvailable,
    };

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/schedule/slot/$stylistId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
    } catch (e) {
      print('Error toggling slot: $e');
    }
    return false;
  }

  static Future<bool> cancelBooking(Booking booking) async {
    final token = await _getToken();

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/bookings/${booking.id}/cancel"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': 'Стилистээр цуцлагдсан',
          'cancelledBy': 'stylist',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }
    } catch (e) {
      print('Cancel booking error: $e');
    }
    return false;
  }

  static String _getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekday = date.weekday;
    return weekday >= 1 && weekday <= 7 ? days[weekday - 1] : 'Monday';
  }

  static String getDayNameMongolian(DateTime date) {
    const days = [
      'Даваа',
      'Мягмар',
      'Лхагва',
      'Пүрэв',
      'Баасан',
      'Бямба',
      'Ням',
    ];
    final weekday = date.weekday;
    return weekday >= 1 && weekday <= 7 ? days[weekday - 1] : 'Даваа';
  }
}
