import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'schedule_service.dart';
import 'ui_widgets.dart';

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
  bool isClosed = false;
  String stylistId = '';

  int totalSlots = 0;
  int bookedSlots = 0;
  int availableSlotsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    stylistId = (await ScheduleService.getStylistId()) ?? '';
    if (stylistId.isNotEmpty) {
      await _refreshSchedule();
    }
    setState(() => isLoading = false);
  }

  Future<void> _refreshSchedule() async {
    await _fetchAvailableSlots();
    await _fetchBookings();
    _updateSlotsWithBookings();
    _calculateStats();
  }

  Future<void> _fetchAvailableSlots() async {
    availableSlots = await ScheduleService.fetchAvailableSlots(
      stylistId,
      selectedDate,
    );
    setState(() {
      hiddenSlots = availableSlots
          .where((slot) => !slot.isAvailable && slot.booking == null)
          .toList();
    });
  }

  Future<void> _fetchBookings() async {
    todaysBookings = await ScheduleService.fetchBookings(
      stylistId,
      selectedDate,
    );
    setState(() {});
  }

  void _updateSlotsWithBookings() {
    for (var booking in todaysBookings) {
      if (booking.status == 'cancelled' || booking.status == 'no_show') {
        continue;
      }

      final slotIndex = availableSlots.indexWhere(
        (slot) => slot.time.trim() == booking.timeSlot.trim(),
      );

      if (slotIndex != -1) {
        availableSlots[slotIndex].isAvailable = false;
        availableSlots[slotIndex].booking = booking;
      }
    }
    setState(() {});
  }

  void _calculateStats() {
    final activeBookings = todaysBookings
        .where(
          (booking) =>
              booking.status != 'cancelled' && booking.status != 'no_show',
        )
        .toList();

    totalSlots = availableSlots.length + hiddenSlots.length;
    availableSlotsCount = availableSlots
        .where((slot) => slot.isAvailable)
        .length;
    bookedSlots = activeBookings.length;
    setState(() {});
  }

  Future<void> _toggleSlotAvailability(TimeSlot slot) async {
    if (slot.booking != null) {
      _showErrorSnackBar('Захиалга бүхий цагийг өөрчлөх боломжгүй');
      return;
    }

    bool success = await ScheduleService.toggleSlotAvailability(
      stylistId,
      slot,
      selectedDate,
    );
    if (success) {
      _showSuccessSnackBar(slot.isAvailable ? 'Цаг хаагдлаа' : 'Цаг нээгдлээ');
      await _refreshSchedule();
    } else {
      _showErrorSnackBar('Алдаа гарлаа');
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    bool? shouldCancel = await showDialog<bool>(
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

    bool success = await ScheduleService.cancelBooking(booking);
    if (success) {
      _showSuccessSnackBar('Захиалга амжилттай цуцлагдлаа');
      await _refreshSchedule();
    } else {
      _showErrorSnackBar('Цуцлахад алдаа гарлаа');
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _refreshSchedule();
    setState(() => isLoading = false);
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
            const Text('Захиалгын мэдээлэл', style: TextStyle(fontSize: 20.0)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UIWidgets.buildDetailRow('Үйлчлүүлэгч:', booking.customerName),
              UIWidgets.buildDetailRow('Үйлчилгээ:', booking.serviceName),
              UIWidgets.buildDetailRow(
                'Огноо:',
                DateFormat('MM/dd/yyyy').format(booking.date),
              ),
              UIWidgets.buildDetailRow('Цаг:', booking.timeSlot),
              UIWidgets.buildDetailRow(
                'Үнэ:',
                '₮${booking.finalPrice.toStringAsFixed(0)}',
              ),
              UIWidgets.buildDetailRow(
                'Төлөв:',
                UIWidgets.getStatusText(booking.status),
              ),
              if (booking.notes.isNotEmpty)
                UIWidgets.buildDetailRow('Тэмдэглэл:', booking.notes),
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
            _buildStatsBar(),
            _buildDatePicker(),
            const SizedBox(height: 16),
            Expanded(child: _buildScheduleList()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: UIWidgets.buildStatCard(
              'Боломжтой',
              availableSlotsCount.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: UIWidgets.buildStatCard(
              'Захиалга',
              bookedSlots.toString(),
              Colors.blue,
              Icons.people,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: UIWidgets.buildStatCard(
              'Хаагдсан',
              hiddenSlots.length.toString(),
              Colors.red,
              Icons.visibility_off,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: UIWidgets.buildStatCard(
              'Нийт',
              totalSlots.toString(),
              Colors.orange,
              Icons.schedule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
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
              setState(() => selectedDate = date);
              await _refreshSchedule();
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
                    ScheduleService.getDayNameMongolian(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    List<TimeSlot> allSlots = [...availableSlots];

    if (showHiddenSlots) {
      for (var hiddenSlot in hiddenSlots) {
        if (!allSlots.any((slot) => slot.time == hiddenSlot.time)) {
          allSlots.add(hiddenSlot);
        }
      }
    }

    for (var booking in todaysBookings) {
      print("booking: $booking");
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
          ],
        ),
      );
    }

    allSlots.sort((a, b) => a.time.compareTo(b.time));

    return Container(
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
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Text(
              '${ScheduleService.getDayNameMongolian(selectedDate)} - ${DateFormat('MM/dd').format(selectedDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allSlots.length,
              itemBuilder: (context, index) {
                final slot = allSlots[index];
                final style = UIWidgets.getSlotStyle(slot);
                return _buildTimeSlotCard(slot, style);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, Map<String, dynamic> style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style['cardColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style['textColor'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style['textColor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(style['icon'], color: style['textColor'], size: 20),
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
                        color: style['textColor'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        style['status'],
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
              if (value == 'toggle') {
                await _toggleSlotAvailability(slot);
              } else if (value == 'booking_details' && slot.booking != null) {
                _showBookingDetails(slot.booking!);
              } else if (value == 'cancel_booking' && slot.booking != null) {
                await _cancelBooking(slot.booking!);
              }
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [];
              if (slot.booking != null) {
                items.add(
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
                );
                if (slot.booking!.status == 'confirmed') {
                  items.add(
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
                  );
                }
              } else if (slot.isAvailable) {
                items.add(
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 18),
                        const SizedBox(width: 8),
                        Text(slot.isAvailable ? 'Хаах' : 'Нээх'),
                      ],
                    ),
                  ),
                );
              }
              return items;
            },
            child: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
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
