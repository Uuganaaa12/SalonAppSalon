import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StylistScheduleWidget extends StatefulWidget {
  const StylistScheduleWidget({super.key});

  @override
  State<StylistScheduleWidget> createState() => _StylistScheduleWidgetState();
}

class _StylistScheduleWidgetState extends State<StylistScheduleWidget> {
  DateTime selectedDate = DateTime.now();
  List<TimeSlot> availableSlots = [];
  List<Booking> todaysBookings = [];
  List<TimeSlot> hiddenSlots = [];
  bool isLoading = true;
  bool showHiddenSlots = false;
  String stylistId = '';
  String baseUrl = 'https://salonapp-l5y6.onrender.com/api';

  int totalSlots = 0;
  int bookedSlots = 0;
  int availableSlotsCount = 0;
  bool isClosed = false;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    stylistId = prefs.getString("stylistId") ?? "";

    if (stylistId.isNotEmpty) {
      await _fetchAvailableSlots();
      await _fetchBookings();
      _updateSlotsWithBookings();
      _calculateStats();
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchAvailableSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/schedule/available/$stylistId/$dateString"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("times data: $data");
        if (data['success'] == true) {
          final slotsData = data['availableSlots'] as List?;
          setState(() {
            availableSlots = (slotsData ?? [])
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
            hiddenSlots = availableSlots
                .where((slot) => !slot.isAvailable && slot.booking == null)
                .toList();

            print("🔍 DEBUG - Available slots details:");
            print("  - Total available slots: ${availableSlots.length}");
            print(
              "  - Slots with isAvailable=false: ${availableSlots.where((slot) => !slot.isAvailable).length}",
            );
            print(
              "  - Slots with bookings: ${availableSlots.where((slot) => slot.booking != null).length}",
            );
            print("  - Hidden slots found: ${hiddenSlots.length}");
            print("  - All slots status:");
            for (int i = 0; i < availableSlots.length; i++) {
              print(
                "    [${i}] ${availableSlots[i].time} -> isAvailable: ${availableSlots[i].isAvailable}, hasBooking: ${availableSlots[i].booking != null}",
              );
            }
          });

          // print("🕒 Available slots loaded: ${availableSlots.length}");
          // print(
          //   "  - Slot times: ${availableSlots.map((s) => '${s.time}(${s.isAvailable ? 'available' : 'booked'})').toList()}",
          // );
        }
      } else if (response.statusCode == 404) {
        print("Salon working hours not configured, using stylist schedule");
        await _fetchStylistSchedule();
      } else {
        print("Error fetching available slots: ${response.statusCode}");
        _showErrorSnackBar('Цагийн хуваарь татахад алдаа гарлаа');
      }
    } catch (e) {
      print("Error fetching available slots: $e");
      await _fetchStylistSchedule();
    }
  }

  Future<void> _fetchStylistSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/stylists/$stylistId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final schedule = data['schedule'] as List?;

        if (schedule != null) {
          final dayName = _getDayName(selectedDate);
          final daySchedule = schedule.firstWhere(
            (day) => day is Map<String, dynamic> && day['day'] == dayName,
            orElse: () => null,
          );

          if (daySchedule != null && daySchedule is Map<String, dynamic>) {
            final slots = daySchedule['slots'] as List?;
            setState(() {
              availableSlots = (slots ?? [])
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

              // Хаагдсан цагуудыг тусад нь хадгалах (захиалгагүй боловч стилистээр хаагдсан цагууд)
              hiddenSlots = availableSlots
                  .where((slot) => !slot.isAvailable && slot.booking == null)
                  .toList();
            });

            // print("🕒 Stylist schedule slots loaded: ${availableSlots.length}");
            // print(
            //   "  - Slot times: ${availableSlots.map((s) => '${s.time}(${s.isAvailable ? 'available' : 'booked'})').toList()}",
            // );
          }
        }
      }
    } catch (e) {
      print("Error fetching stylist schedule: $e");
      _showErrorSnackBar('Стилистийн хуваарь татахад алдаа гарлаа');
    }
  }

  Future<void> _fetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    // print("🔍 Fetching bookings for date: $dateString");
    // print("🔍 Selected date object: $selectedDate");
    // print(
    //   "🔍 Request URL: $baseUrl/bookings/stylist/$stylistId?date=$dateString",
    // );

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/stylist/$stylistId?date=$dateString"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // print("Response data: $responseData");

        List<dynamic> bookingsData = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData['bookings'] != null) {
            bookingsData = responseData['bookings'] as List;

            // print(
            //   "📅 Found ${bookingsData.length} bookings for requested date: $dateString",
            // );
            // for (var booking in bookingsData) {
            //   if (booking is Map<String, dynamic>) {
            //     print(
            //       "  - Booking date: ${booking['date']}, Time: ${booking['timeSlot']}, Status: ${booking['status']}",
            //     );
            //   }
            // }

            // Статистик мэдээлэл хадгалах
            // if (responseData['stats'] != null) {
            //   final stats = responseData['stats'];
            //   print("Today's stats: ${stats.toString()}");
            // }
          } else {
            print("No bookings found or API returned unsuccessful response");
            bookingsData = [];
          }
        } else if (responseData is List) {
          // Хуучин формат дэмжих
          bookingsData = responseData;
        }

        setState(() {
          // Захиалгуудыг сонгосон өдрөөр нэмэлт шүүнэ (цагийн бүсийн асуудлыг арилгахын тулд)
          final selectedDateString = DateFormat(
            'yyyy-MM-dd',
          ).format(selectedDate);

          todaysBookings = bookingsData
              .map((booking) {
                try {
                  if (booking is Map<String, dynamic>) {
                    final bookingObj = Booking.fromJson(booking);

                    // Захиалгын огнооны зөвхөн огнооны хэсгийг авч харьцуулна
                    final bookingDateString = DateFormat(
                      'yyyy-MM-dd',
                    ).format(bookingObj.date);

                    // print(
                    //   "📋 Comparing: booking date '$bookingDateString' with selected '$selectedDateString', status: '${bookingObj.status}'",
                    // );

                    // Зөвхөн тухайн өдрийн ИДЭВХТЭЙ захиалгыг буцаана (цуцлагдсан захиалгыг үл харгалзана)
                    if (bookingDateString == selectedDateString &&
                        bookingObj.status != 'cancelled' &&
                        bookingObj.status != 'no_show') {
                      return bookingObj;
                    } else {
                      if (bookingObj.status == 'cancelled' ||
                          bookingObj.status == 'no_show') {
                        print("  ❌ Excluding cancelled/no_show booking");
                      } else {
                        print("  ❌ Date mismatch - excluding booking");
                      }
                      return null;
                    }
                  } else {
                    print("Invalid booking data format: $booking");
                    return null;
                  }
                } catch (e) {
                  print("Error parsing individual booking: $e");
                  return null;
                }
              })
              .where((booking) => booking != null)
              .cast<Booking>()
              .toList();

          print("✅ Final filtered bookings: ${todaysBookings.length}");
        });
      } else {
        print("Error fetching bookings: ${response.statusCode}");
        print("Response body: ${response.body}");
        _showErrorSnackBar('Захиалга татахад алдаа гарлаа!');
      }
    } catch (e) {
      print("Error fetching bookings: $e");
      _showErrorSnackBar('Захиалга татахад алдаа гарлаа!!');
    }
  }

  void _updateSlotsWithBookings() {
    // print("🔄 Updating slots with bookings...");
    // print("  - Available slots count: ${availableSlots.length}");
    // print("  - Today's bookings count: ${todaysBookings.length}");

    // Mark slots as booked if they have ACTIVE bookings only
    for (var booking in todaysBookings) {
      // Зөвхөн идэвхтэй захиалгуудыг slot-д хамруулах
      if (booking.status == 'cancelled' || booking.status == 'no_show') {
        print(
          "  - Skipping cancelled/no_show booking for time: '${booking.timeSlot}'",
        );
        continue;
      }

      // print(
      //   "  - Processing ACTIVE booking for time: '${booking.timeSlot}' (${booking.timeSlot.runtimeType}), status: ${booking.status}",
      // );

      final slotIndex = availableSlots.indexWhere(
        (slot) => slot.time.trim() == booking.timeSlot.trim(),
      );

      if (slotIndex != -1) {
        // print("    ✅ Found matching slot at index $slotIndex");
        availableSlots[slotIndex].isAvailable = false;
        availableSlots[slotIndex].booking = booking;
        // print(
        //   "    📝 Slot updated: ${availableSlots[slotIndex].time} -> booked",
        // );
      } else {
        print("    ❌ No matching slot found for time: '${booking.timeSlot}'");
        print(
          "    Available slot times: ${availableSlots.map((s) => "'${s.time}'").toList()}",
        );
        print("    Exact comparison:");
        for (var slot in availableSlots) {
          final isMatch = slot.time.trim() == booking.timeSlot.trim();
          print("      '${slot.time}' == '${booking.timeSlot}' : $isMatch");
        }
      }
    }

    final bookedSlotsCount = availableSlots
        .where((slot) => !slot.isAvailable)
        .length;
    print("  - Final booked slots count: $bookedSlotsCount");
  }

  void _calculateStats() {
    final activeBookings = todaysBookings
        .where(
          (booking) =>
              booking.status != 'cancelled' && booking.status != 'no_show',
        )
        .toList();

    totalSlots =
        availableSlots.length + activeBookings.length + hiddenSlots.length;
    availableSlotsCount = availableSlots
        .where((slot) => slot.isAvailable)
        .length;
    bookedSlots = activeBookings.length;
  }

  String _getDayName(DateTime date) {
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
    if (weekday >= 1 && weekday <= 7) {
      return days[weekday - 1];
    }
    return 'Monday'; // Default fallback
  }

  String _getDayNameMongolian(DateTime date) {
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
    if (weekday >= 1 && weekday <= 7) {
      return days[weekday - 1];
    }
    return 'Даваа'; // Default fallback
  }

  Future<void> _toggleSlotAvailability(TimeSlot slot) async {
    if (slot.booking != null) {
      _showErrorSnackBar('Захиалга бүхий цагийг өөрчлөх боломжгүй');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dayName = _getDayName(selectedDate);

    final requestData = {
      'day': dayName,
      'time': slot.time,
      'isAvailable': !slot.isAvailable,
    };

    print("🔄 Toggling slot availability:");
    print("  - Day: $dayName");
    print("  - Time: ${slot.time}");
    print("  - Current: ${slot.isAvailable}");
    print("  - New: ${!slot.isAvailable}");
    print("  - Request data: $requestData");

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
        print("✅ Toggle response: $responseData");

        // API-ээс амжилттай хариу ирвэл slot-ийг шинэчлэх
        if (responseData['success'] == true) {
          final message =
              responseData['message'] ??
              (slot.isAvailable ? 'Цаг хаагдлаа' : 'Цаг нээгдлээ');
          _showSuccessSnackBar(message);

          // Server-ээс available slots-г дахин татаж, UI-г шинэчлэх
          await _fetchAvailableSlots();
          await _fetchBookings();
          _updateSlotsWithBookings();
          _calculateStats();
        } else {
          _showErrorSnackBar(responseData['message'] ?? 'Алдаа гарлаа');
        }
      } else {
        final responseData = jsonDecode(response.body);
        print("❌ Toggle failed with status: ${response.statusCode}");
        print("❌ Response: $responseData");
        _showErrorSnackBar(responseData['message'] ?? 'Серверийн алдаа');
      }
    } catch (e) {
      print('❌ Slot toggle error: $e');
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  Future<void> _enableHiddenSlot(TimeSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dayName = _getDayName(selectedDate);

    final requestData = {
      'day': dayName,
      'time': slot.time,
      'isAvailable': true, // Заавал нээх
    };

    print("🔓 Enabling hidden slot:");
    print("  - Day: $dayName");
    print("  - Time: ${slot.time}");

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

        if (responseData['success'] == true) {
          _showSuccessSnackBar('${slot.time} цаг амжилттай нээгдлээ');

          // Өгөгдлийг дахин татах
          await _fetchAvailableSlots();
          await _fetchBookings();
          _updateSlotsWithBookings();
          _calculateStats();
        } else {
          _showErrorSnackBar(responseData['message'] ?? 'Алдаа гарлаа');
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackBar(responseData['message'] ?? 'Серверийн алдаа');
      }
    } catch (e) {
      print('❌ Enable slot error: $e');
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Захиалга цуцлах'),
          content: Text(
            '${booking.customerName}-ын ${booking.timeSlot} цагийн захиалгыг цуцлах уу?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Үгүй'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Тийм'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

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

        if (responseData['success'] == true) {
          _showSuccessSnackBar('Захиалга амжилттай цуцлагдлаа');
          // Өгөгдлийг дахин татах зөв дарааллаар
          await _fetchAvailableSlots();
          await _fetchBookings();
          _updateSlotsWithBookings();
          _calculateStats();
        } else {
          _showErrorSnackBar(
            responseData['message'] ?? 'Цуцлахад алдаа гарлаа',
          );
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackBar(responseData['message'] ?? 'Серверийн алдаа');
      }
    } catch (e) {
      print('Cancel booking error: $e');
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    try {
      await _fetchAvailableSlots();
      await _fetchBookings();
      _updateSlotsWithBookings();
      _calculateStats();
    } catch (e) {
      print('Refresh error: $e');
      _showErrorSnackBar('Өгөгдөл шинэчлэхэд алдаа гарлаа');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Өдрийн хяналтын диалог харуулах
  Future<void> _showDayControlDialog() async {
    final totalSlots = availableSlots.length;
    final availableCount = availableSlots
        .where((slot) => slot.isAvailable && slot.booking == null)
        .length;
    final hiddenCount = hiddenSlots.length;
    final bookedCount = availableSlots
        .where((slot) => slot.booking != null)
        .length;

    final isCompletelyHidden = availableCount == 0 && bookedCount == 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_busy, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Өдрийн хяналт'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getDayNameMongolian(selectedDate)} - ${DateFormat('MM/dd').format(selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusRow('Нийт цаг:', '$totalSlots', Colors.orange),
              _buildStatusRow('Боломжтой:', '$availableCount', Colors.green),
              _buildStatusRow('Захиалгатай:', '$bookedCount', Colors.blue),
              _buildStatusRow('Хаагдсан:', '$hiddenCount', Colors.red),
              const SizedBox(height: 16),
              if (bookedCount > 0 && !isCompletelyHidden)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Захиалгатай цагууд байна. Тэдгээрийг эхлээд цуцлах шаардлагатай.',
                          style: TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Хаах'),
            ),
            if (isCompletelyHidden)
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openEntireDay();
                },
                icon: const Icon(Icons.event_available, color: Colors.green),
                label: const Text(
                  'Өдөр нээх',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            if (!isCompletelyHidden && bookedCount == 0)
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _closeEntireDay();
                },
                icon: const Icon(Icons.event_busy, color: Colors.red),
                label: const Text(
                  'Өдөр хаах',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
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

  // Өдөр бүтнээр хаах
  Future<void> _closeEntireDay() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dayName = _getDayName(selectedDate);

    // Захиалгатай цагууд байгаа эсэхийг шалгах
    final bookedSlots = availableSlots
        .where((slot) => slot.booking != null)
        .toList();
    if (bookedSlots.isNotEmpty) {
      _showErrorSnackBar(
        'Захиалгатай цагууд байна. Эхлээд тэдгээрийг цуцлана уу.',
      );
      return;
    }

    try {
      // Боломжтой бүх цагийг хаах
      final availableSlotsToClose = availableSlots
          .where((slot) => slot.isAvailable && slot.booking == null)
          .toList();

      if (availableSlotsToClose.isEmpty) {
        _showSuccessSnackBar('Өдөр аль хэдийн хаагдсан байна');
        return;
      }

      setState(() => isLoading = true);

      for (var slot in availableSlotsToClose) {
        final requestData = {
          'day': dayName,
          'time': slot.time,
          'isAvailable': false,
        };

        final response = await http.put(
          Uri.parse("$baseUrl/schedule/slot/$stylistId"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        if (response.statusCode != 200) {
          final responseData = jsonDecode(response.body);
          print(
            "❌ Failed to close slot ${slot.time}: ${responseData['message']}",
          );
        }
      }

      _showSuccessSnackBar(
        '${_getDayNameMongolian(selectedDate)} өдөр амжилттай хаагдлаа',
      );
      isClosed = true;
      await _fetchAvailableSlots();
      await _fetchBookings();
      _updateSlotsWithBookings();
      _calculateStats();
    } catch (e) {
      print('❌ Close entire day error: $e');
      _showErrorSnackBar('Алдаа гарлаа: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Өдөр бүтнээр нээх
  Future<void> _openEntireDay() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final dayName = _getDayName(selectedDate);

    try {
      setState(() => isLoading = true);

      // Хаагдсан бүх цагийг нээх
      for (var slot in hiddenSlots) {
        final requestData = {
          'day': dayName,
          'time': slot.time,
          'isAvailable': true,
        };

        final response = await http.put(
          Uri.parse("$baseUrl/schedule/slot/$stylistId"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        if (response.statusCode != 200) {
          final responseData = jsonDecode(response.body);
          print(
            "❌ Failed to open slot ${slot.time}: ${responseData['message']}",
          );
        }
      }

      _showSuccessSnackBar(
        '${_getDayNameMongolian(selectedDate)} өдөр амжилттай нээгдлээ',
      );
      isClosed = false;
      await _fetchAvailableSlots();
      await _fetchBookings();
      _updateSlotsWithBookings();
      _calculateStats();
    } catch (e) {
      print('❌ Open entire day error: $e');
      _showErrorSnackBar('Алдаа гарлаа: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Боломжтой',
                      availableSlotsCount.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Захиалга',
                      bookedSlots.toString(),
                      Colors.blue,
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Хаагдсан',
                      hiddenSlots.length.toString(),
                      Colors.red,
                      Icons.visibility_off,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Нийт',
                      totalSlots.toString(),
                      Colors.orange,
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
            ),

            // Date Picker
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected =
                      DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(selectedDate);

                  return GestureDetector(
                    onTap: () async {
                      print(
                        "🗓️ Date selected: ${DateFormat('yyyy-MM-dd').format(date)}",
                      );
                      setState(() => selectedDate = date);
                      print("🔄 Refreshing data for new date...");

                      // Эхлээд available slots-г татна
                      await _fetchAvailableSlots();
                      // Дараа нь bookings-г татна
                      await _fetchBookings();
                      // Хоёуланг дууссаны дараа slots-г update хийнэ
                      _updateSlotsWithBookings();
                      _calculateStats();
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.white,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayNameMongolian(date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[800],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Schedule List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_getDayNameMongolian(selectedDate)} - ${DateFormat('MM/dd').format(selectedDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (availableSlots.isNotEmpty ||
                              todaysBookings.isNotEmpty) ...[
                            const Spacer(),
                            FilledButton(
                              onPressed: _showDayControlDialog,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    color: Color(0xFF1F2937),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Өдөр ${isClosed ? "нээх" : "хаах"}'),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(child: _buildScheduleList()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    List<TimeSlot> allSlots = [];

    // Бүх цагуудыг авах (боломжтой болон захиалгатай)
    allSlots.addAll(availableSlots);

    // Хаагдсан цагуудыг харуулах эсэхээс хамааран нэмэх (зөвхөн стилистээр хаагдсан цагууд)
    if (showHiddenSlots) {
      for (var hiddenSlot in hiddenSlots) {
        // Давхардал шалгах
        final exists = allSlots.any((slot) => slot.time == hiddenSlot.time);
        if (!exists) {
          allSlots.add(hiddenSlot);
        }
      }
    }

    // Захиалгуудыг нэмэх (хэрэв тэдгээр slot байхгүй бол)
    for (var booking in todaysBookings) {
      // Зөвхөн идэвхтэй захиалгуудыг харуулах
      if (booking.status == 'cancelled' || booking.status == 'no_show') {
        continue;
      }

      final existingSlot = allSlots.firstWhere(
        (slot) => slot.time == booking.timeSlot,
        orElse: () => TimeSlot(time: '', isAvailable: true),
      );

      if (existingSlot.time.isEmpty) {
        allSlots.add(
          TimeSlot(
            time: booking.timeSlot,
            isAvailable: false,
            booking: booking,
          ),
        );
      } else if (existingSlot.booking == null) {
        // Slot байгаа боловч booking байхгүй бол нэмэх
        existingSlot.booking = booking;
        existingSlot.isAvailable = false;
      }
    }

    if (allSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Амралтын өдөр',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Text(
            //   '${_getDayNameMongolian(selectedDate)} өдөр хаагдсан байна',
            //   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            //   textAlign: TextAlign.center,
            // ),
            // const SizedBox(height: 20),
            // ElevatedButton.icon(
            //   onPressed: _openEntireDay,
            //   icon: const Icon(Icons.event_available, size: 20),
            //   label: const Text('Өдөр нээх'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.teal,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 24,
            //       vertical: 12,
            //     ),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(25),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
    allSlots.sort((a, b) => a.time.compareTo(b.time));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSlots.length,
            itemBuilder: (context, index) {
              final slot = allSlots[index];
              return _buildTimeSlotCard(slot, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
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

  Widget _buildTimeSlotCard(TimeSlot slot, int index) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String status;

    if (slot.booking != null) {
      final bookingStatus = slot.booking!.status;
      switch (bookingStatus) {
        // case 'pending':
        //   cardColor = const Color(0xFFFEF3C7);
        //   textColor = const Color(0xFFD97706);
        //   icon = Icons.schedule;
        //   status = 'Хүлээгдэж буй';
        //   break;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.time,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: textColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (slot.booking != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    slot.booking!.customerName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (slot.booking!.serviceName.isNotEmpty)
                    Text(
                      slot.booking!.serviceName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'toggle':
                  await _toggleSlotAvailability(slot);
                  break;
                case 'enable_hidden':
                  await _enableHiddenSlot(slot);
                  break;
                case 'booking_details':
                  if (slot.booking != null) {
                    _showBookingDetails(slot.booking!);
                  }
                  break;
                case 'cancel_booking':
                  if (slot.booking != null) {
                    await _cancelBooking(slot.booking!);
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [];

              if (slot.booking != null) {
                items.addAll([
                  const PopupMenuItem(
                    value: 'booking_details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Захиалгын мэдээлэл'),
                      ],
                    ),
                  ),
                  if (slot.booking!.status == 'confirmed')
                    const PopupMenuItem(
                      value: 'cancel_booking',
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Захиалга цуцлах',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ]);
              } else {
                // Хаагдсан цагийн хувьд "Нээх" сонголт нэмэх
                if (!slot.isAvailable) {
                  items.addAll([
                    const PopupMenuItem(
                      value: 'enable_hidden',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Цаг нээх',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ]);
                } else {
                  items.addAll([
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            slot.isAvailable ? Icons.close : Icons.check,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(slot.isAvailable ? 'Хаах' : 'Нээх'),
                        ],
                      ),
                    ),
                  ]);
                }
              }

              return items;
            },
            child: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            const Text('Захиалгын мэдээлэл'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Үйлчлүүлэгч:', booking.customerName),
              _buildDetailRow('Үйлчилгээ:', booking.serviceName),
              _buildDetailRow(
                'Огноо:',
                DateFormat('MM/dd/yyyy').format(booking.date),
              ),
              _buildDetailRow('Цаг:', booking.timeSlot),
              _buildDetailRow(
                'Үнэ:',
                '₮${booking.finalPrice.toStringAsFixed(0)}',
              ),
              _buildDetailRow('Төлөв:', _getStatusText(booking.status)),
              if (booking.notes.isNotEmpty)
                _buildDetailRow('Тэмдэглэл:', booking.notes),
            ],
          ),
        ),
        actions: [
          if (booking.status == 'confirmed')
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelBooking(booking);
              },
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Цуцлах', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  String _getStatusText(String status) {
    switch (status) {
      // case 'pending':
      //   return 'Хүлээгдэж буй';
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

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
