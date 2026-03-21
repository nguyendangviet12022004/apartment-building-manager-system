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
  bool _isLoadingSchedule = false;
  bool _isSubmitting = false;

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
      setState(() {
        _confirmedBookings = schedule;
      });
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    } finally {
      setState(() {
        _isLoadingSchedule = false;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                "Khung giờ đã kín (Busy)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingSchedule
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _confirmedBookings.isEmpty
                    ? const Center(
                        child: Text(
                          "Hôm nay trống cả ngày",
                          style: TextStyle(color: Colors.green),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: _confirmedBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _confirmedBookings[index];
                          final start = DateTime.parse(item['startTime']);
                          final end = DateTime.parse(item['endTime']);
                          return Chip(
                            label: Text(
                              '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                          );
                        },
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
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() {
                      if (_quantity < 20) _quantity++;
                    }),
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
