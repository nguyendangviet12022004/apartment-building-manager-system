import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calendar_booking_model.dart';
import '../services/booking_service.dart';
import '../routes/app_routes.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

enum CalendarView { day, week, month }

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final BookingService _bookingService = BookingService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarView _currentView = CalendarView.month;
  
  Map<DateTime, List<CalendarBookingModel>> _bookingsByDate = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load bookings for the entire month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final response = await _bookingService.getCalendarBookings(
        startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
        endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
        viewType: 'MONTH',
      );

      setState(() {
        _bookingsByDate = _groupBookingsByDate(response.bookings);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<CalendarBookingModel>> _groupBookingsByDate(List<CalendarBookingModel> bookings) {
    Map<DateTime, List<CalendarBookingModel>> grouped = {};
    for (var booking in bookings) {
      final date = DateTime(
        booking.startTime.year,
        booking.startTime.month,
        booking.startTime.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(booking);
    }
    return grouped;
  }

  List<CalendarBookingModel> _getBookingsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Color(0xFF88304E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildViewSelector(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    if (_currentView == CalendarView.month) _buildCalendar(),
                    Expanded(child: _buildContentByView()),
                  ],
                ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildViewSelector() {
    return PopupMenuButton<CalendarView>(
      icon: const Icon(Icons.view_agenda, color: Color(0xFF88304E)),
      onSelected: (CalendarView view) {
        setState(() {
          _currentView = view;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<CalendarView>>[
        const PopupMenuItem<CalendarView>(
          value: CalendarView.day,
          child: Row(
            children: [
              Icon(Icons.view_day, size: 20),
              SizedBox(width: 12),
              Text('Day'),
            ],
          ),
        ),
        const PopupMenuItem<CalendarView>(
          value: CalendarView.week,
          child: Row(
            children: [
              Icon(Icons.view_week, size: 20),
              SizedBox(width: 12),
              Text('Week'),
            ],
          ),
        ),
        const PopupMenuItem<CalendarView>(
          value: CalendarView.month,
          child: Row(
            children: [
              Icon(Icons.calendar_month, size: 20),
              SizedBox(width: 12),
              Text('Month'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentByView() {
    switch (_currentView) {
      case CalendarView.day:
        return _buildDayView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.month:
        return _buildMonthView();
    }
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month - 1,
                        );
                      });
                      _loadBookings();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month + 1,
                        );
                      });
                      _loadBookings();
                    },
                  ),
                ],
              ),
            ],
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadBookings();
            },
            eventLoader: _getBookingsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) {
                      final booking = event as CalendarBookingModel;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _getServiceColor(booking.serviceIcon),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF88304E),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF88304E).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            headerVisible: false,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(String iconName) {
    switch (iconName) {
      case 'bbq':
        return const Color(0xFFEF4444); // Red
      case 'pool':
        return const Color(0xFF3B82F6); // Blue
      case 'gym':
        return const Color(0xFF10B981); // Green
      case 'tennis':
        return const Color(0xFFF59E0B); // Orange
      case 'parking':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF88304E); // Default purple
    }
  }

  // Month View - List of bookings for selected day
  Widget _buildMonthView() {
    final bookingsForDay = _getBookingsForDay(_selectedDay);
    
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bookingsForDay.length} SCHEDULED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: bookingsForDay.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookingsForDay.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(bookingsForDay[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Day View - Timeline with hourly slots
  Widget _buildDayView() {
    final bookingsForDay = _getBookingsForDay(_selectedDay);
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.subtract(const Duration(days: 1));
                          _focusedDay = _selectedDay;
                        });
                      },
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.add(const Duration(days: 1));
                          _focusedDay = _selectedDay;
                        });
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bookingsForDay.length} events',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Timeline
          Expanded(
            child: bookingsForDay.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookingsForDay.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineBookingCard(bookingsForDay[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Week View - 7 columns with bookings
  Widget _buildWeekView() {
    final startOfWeek = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Week header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.subtract(const Duration(days: 7));
                          _focusedDay = _selectedDay;
                        });
                      },
                    ),
                    Text(
                      '${DateFormat('MMM d').format(weekDays.first)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.add(const Duration(days: 7));
                          _focusedDay = _selectedDay;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Week day headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: weekDays.map((day) {
                final isToday = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(day, _selectedDay);
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isToday ? const Color(0xFF88304E) : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF88304E) 
                              : isToday 
                                  ? const Color(0xFF88304E).withOpacity(0.1)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? Colors.white 
                                : isToday 
                                    ? const Color(0xFF88304E)
                                    : const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Week grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekDays.map((day) {
                final bookings = _getBookingsForDay(day);
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFE5E7EB),
                          width: day == weekDays.last ? 0 : 1,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        return _buildWeekBookingCard(bookings[index]);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBookingCard(CalendarBookingModel booking) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetail,
          arguments: booking.bookingId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getServiceColor(booking.serviceIcon).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: _getServiceColor(booking.serviceIcon),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getServiceIcon(booking.serviceIcon),
                  size: 18,
                  color: _getServiceColor(booking.serviceIcon),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  booking.timeSlot,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.apartment, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  booking.apartmentCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              booking.residentName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekBookingCard(CalendarBookingModel booking) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetail,
          arguments: booking.bookingId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _getServiceColor(booking.serviceIcon),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.serviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              booking.timeSlot,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(CalendarBookingModel booking) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetail,
          arguments: booking.bookingId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: _getServiceColor(booking.serviceIcon),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getServiceIcon(booking.serviceIcon),
                        size: 16,
                        color: _getServiceColor(booking.serviceIcon),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AMENITY',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'APPROVED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking.serviceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Text(
                    'Time Slot',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking.timeSlot,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.apartment, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Text(
                    'Apartment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking.apartmentCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    booking.residentName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String iconName) {
    switch (iconName) {
      case 'bbq':
        return Icons.outdoor_grill;
      case 'pool':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      case 'tennis':
        return Icons.sports_tennis;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.room_service;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Approved bookings will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unable to load calendar',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF88304E),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'HOME', false, AppRoutes.adminHome),
              _buildNavItem(Icons.grid_view, 'Calendar', true, null),
              _buildNavItem(Icons.receipt_long_outlined, 'INVOICES', false, AppRoutes.invoiceList),
              _buildNavItem(Icons.person_outline, 'PROFILE', false, AppRoutes.profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, String? route) {
    return InkWell(
      onTap: route != null
          ? () => Navigator.of(context, rootNavigator: true).pushNamed(route)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF88304E) : const Color(0xFF9CA3AF),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF88304E) : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
