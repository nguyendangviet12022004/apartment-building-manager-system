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

  late DateTime _selectedDate;
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
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(
      const Duration(days: 1),
    ); // Mặc định là ngày mai
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoadingSchedule = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
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
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // --- VALIDATION LOGIC ---
    if (startDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đặt chỗ trong quá khứ')),
      );
      return;
    }

    if (endDateTime.difference(startDateTime).inMinutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian đặt chỗ tối thiểu là 1 tiếng')),
      );
      return;
    }

    if (startDateTime.isAfter(endDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian bắt đầu phải trước thời gian kết thúc'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

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

      // Show success and pop
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thành công'),
          content: const Text('Yêu cầu đặt chỗ đã được gửi!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    // Tính ngày cuối cùng của tháng hiện tại
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (_selectedDate.isAfter(lastDayOfMonth) || _selectedDate.isBefore(now))
          ? now
          : _selectedDate,
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
                '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.service.unitPrice)} / ${widget.service.unit}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Date Picker
              const Text(
                "Ngày đặt",
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
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Schedule Visualization
              const Text(
                "Biểu đồ số lượng đặt chỗ (0h - 24h)",
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
                          "Bắt đầu",
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
                          "Kết thúc",
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
                "Số lượng / Số khách",
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
                    'Còn lại: $remainingCapacity / ${widget.service.capacity}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Note
              const Text(
                "Ghi chú",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Nhập ghi chú nếu có...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Xác nhận đặt chỗ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
