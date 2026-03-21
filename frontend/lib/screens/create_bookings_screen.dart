import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../services/service_api.dart';

class CreateBookingsScreen extends StatefulWidget {
  final ServiceModel service;

  const CreateBookingsScreen({Key? key, required this.service})
    : super(key: key);

  @override
  State<CreateBookingsScreen> createState() => _CreateBookingsScreenState();
}

class _CreateBookingsScreenState extends State<CreateBookingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceApi _serviceApi = ServiceApi();

  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  List<dynamic> _confirmedBookings = [];
  List<int> _hourlyUsage = List.filled(24, 0); // Data cho biểu đồ 24h
  bool _isLoadingSchedule = false;
  bool _isSubmitting = false;

  /// Tính toán tổng số lượng đã được đặt trong khung giờ đang chọn.
  /// Nó sẽ quét qua các booking đã được xác nhận hoặc đang chờ duyệt.
  int get _currentUsage {
    if (_selectedDate == null) return 0;

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (startDateTime.isAfter(endDateTime)) return 0;

    int usage = 0;
    for (var booking in _confirmedBookings) {
      final bookingStart = DateTime.parse(booking['startTime']);
      final bookingEnd = DateTime.parse(booking['endTime']);

      // Kiểm tra xem booking có bị trùng lặp thời gian không
      if (bookingStart.isBefore(endDateTime) &&
          bookingEnd.isAfter(startDateTime)) {
        usage += (booking['quantity'] as int? ?? 1);
      }
    }
    return usage;
  }

  /// Tính tổng tiền dự kiến (Client-side estimation)
  double get _estimatedTotal {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) return 0.0;

    if (widget.service.unit?.toLowerCase() == 'hour') {
      int durationInMinutes = endMinutes - startMinutes;
      int hours = (durationInMinutes / 60).ceil(); // Làm tròn lên như Backend
      return (widget.service.unitPrice * hours * _quantity).toDouble();
    } else {
      return (widget.service.unitPrice * _quantity).toDouble();
    }
  }

  @override
  void initState() {
    super.initState();
    // Không chọn ngày mặc định để người dùng buộc phải chọn
  }

  Future<void> _fetchSchedule() async {
    if (_selectedDate == null) return;
    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final schedule = await _serviceApi.getBookingSchedule(
        widget.service.id,
        dateStr,
      );

      // Tính toán số lượng đặt cho từng khung giờ (0h-23h)
      final List<int> usageList = List.filled(24, 0);

      // Pre-process bookings để tránh parse lặp lại và xử lý lỗi dữ liệu từng item
      final validBookings = [];
      for (var booking in schedule) {
        try {
          validBookings.add({
            'start': DateTime.parse(booking['startTime']),
            'end': DateTime.parse(booking['endTime']),
            // Sử dụng num? để chấp nhận cả int và double, sau đó toInt()
            'qty': (booking['quantity'] as num?)?.toInt() ?? 1,
          });
        } catch (e) {
          debugPrint('Invalid booking data skipped: $e');
        }
      }

      for (int h = 0; h < 24; h++) {
        final slotStart = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          h,
          0,
        );
        final slotEnd = slotStart.add(const Duration(hours: 1));

        for (var b in validBookings) {
          final bStart = b['start'] as DateTime;
          final bEnd = b['end'] as DateTime;
          final qty = b['qty'] as int;

          // Kiểm tra giao nhau: Booking có trùng vào giờ 'h' không?
          // Logic: (StartA < EndB) && (EndA > StartB) là công thức kiểm tra giao nhau chuẩn
          if (bStart.isBefore(slotEnd) && bEnd.isAfter(slotStart)) {
            usageList[h] += qty;
          }
        }
      }

      setState(() {
        _confirmedBookings = schedule;
        _hourlyUsage = usageList;
      });
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    // Note: Validations are now handled in _showConfirmationDialog
    setState(() => _isSubmitting = true);

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime.hour,
      _endTime.minute,
    );

    try {
      final bookingData = {
        'serviceId': widget.service.id,
        'startTime': startDateTime.toIso8601String(),
        'endTime': endDateTime.toIso8601String(),
        'quantity': _quantity,
        'note': _noteController.text,
      };

      await _serviceApi.createBooking(bookingData);

      if (!mounted) return;

      // Show a success message and automatically navigate back.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to ServiceListScreen
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final safeInitialDate = _selectedDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: now,
      lastDate: lastDayOfMonth,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSchedule();
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }

        // Sau khi đổi giờ, kiểm tra lại xem số lượng hiện tại có hợp lệ không.
        // Nếu không, reset về 1 hoặc giá trị tối đa cho phép.
        final remaining = widget.service.capacity - _currentUsage;
        if (_quantity > remaining) {
          _quantity = remaining > 0 ? remaining : 1;
        }
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    // --- VALIDATION LOGIC ---
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (startDateTime.isBefore(now)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot book in the past.')));
      return;
    }

    if (endDateTime.difference(startDateTime).inMinutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum booking duration is 1 hour.')),
      );
      return;
    }

    if (startDateTime.isAfter(endDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time.')),
      );
      return;
    }

    // If all validations pass, show the dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Your Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please review your booking details:'),
            const SizedBox(height: 16),
            _buildSummaryRow('Service:', widget.service.serviceName),
            _buildSummaryRow(
              'Date:',
              DateFormat('dd/MM/yyyy').format(_selectedDate!),
            ),
            _buildSummaryRow(
              'Time:',
              '${_startTime.format(context)} - ${_endTime.format(context)}',
            ),
            _buildSummaryRow('Quantity:', '$_quantity'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total:',
              NumberFormat.currency(
                locale: 'en_US',
                symbol: 'VND ',
              ).format(_estimatedTotal),
              isTotal: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitBooking();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số chỗ còn lại và khả năng tăng số lượng
    final int remainingCapacity = widget.service.capacity - _currentUsage;
    final bool canIncrease = _quantity < remainingCapacity;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Create Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info
              Text(
                widget.service.serviceName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${NumberFormat.currency(locale: 'en_US', symbol: 'VND ').format(widget.service.unitPrice)} / ${widget.service.unit}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Date Picker
              const Text(
                "Booking Date",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? "Tap to select a date"
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDate != null) ...[
                // Schedule Visualization
                const Text(
                  "Booking Usage Chart (0h - 24h)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _isLoadingSchedule
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Biểu đồ cột
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(24, (index) {
                                  final usage = _hourlyUsage[index];
                                  final capacity = widget.service.capacity;
                                  // Tính chiều cao cột tương đối (max 100%)
                                  final double fill = capacity > 0
                                      ? (usage / capacity).clamp(0.0, 1.0)
                                      : 0.0;

                                  // Màu sắc cảnh báo
                                  Color color = Colors.green;
                                  if (fill >= 1.0)
                                    color = Colors.red;
                                  else if (fill >= 0.5)
                                    color = Colors.orange;
                                  if (usage == 0) color = Colors.grey.shade200;

                                  return Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (usage > 0)
                                          Text(
                                            '$usage',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          height:
                                              120 * fill +
                                              (usage > 0 ? 4 : 2), // Min height
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Trục hoành (Giờ)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '6h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '12h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '18h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '24h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // Time Picker
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Start Time",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_startTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "End Time",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_endTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quantity
                const Text(
                  "Quantity / Guests",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        if (_quantity > 1) _quantity--;
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      // Nút bị vô hiệu hóa nếu không thể tăng số lượng
                      onPressed: canIncrease
                          ? () => setState(() {
                              _quantity++;
                            })
                          : null,
                    ),
                    const Spacer(),
                    // Hiển thị số chỗ còn lại
                    Text(
                      'Available: $remainingCapacity / ${widget.service.capacity}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Note
                const Text(
                  "Note",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a note if any...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Total Price Estimation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Estimated Total:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'en_US',
                          symbol: 'VND ',
                        ).format(_estimatedTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _showConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 16,
              color: isTotal
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
