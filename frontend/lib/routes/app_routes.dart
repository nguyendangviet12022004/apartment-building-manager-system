import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/resident_home_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/apartment_verify_screen.dart';
import '../screens/admin_request_screen.dart';
import '../screens/create_invoice_page.dart';
import '../screens/invoice_list_management_screen.dart';
import '../screens/request_detail_response_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resident_management_screen.dart';
import '../screens/booking_requests_screen.dart';
import '../screens/booking_calendar_screen.dart';
import '../screens/add_apartment_screen.dart';
import '../screens/manager_generate_access_code_screen.dart';
import '../screens/manager_create_notification_screen.dart';
import '../screens/apartment_list_screen.dart';
import '../screens/apartment_detail_screen.dart';
import '../screens/edit_apartment_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../models/request_model.dart';
import '../screens/request_list_screen.dart';
import '../screens/create_request_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String residentHome = '/resident-home';
  static const String adminHome = '/admin-home';
  static const String adminRequests = '/admin-requests';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  static const String verifyApartment = '/verify-apartment';
  static const String notifications = '/notifications';
  static const String bills = '/bills';
  static const String createInvoice = '/create-invoice';
  static const String invoiceList = '/invoice-list';
  static const String paymentHistory = '/payment-history';
  static const String requestDetailResponse = '/admin/request-response';

  static const String addApartment = '/add-apartment';
  static const String profile = '/profile';
  static const String residentManagement = '/resident-management';
  static const String bookingRequests = '/booking-requests';
  static const String bookingCalendar = '/booking-calendar';
  static const String bookingDetail = '/booking-detail';
  static const String apartmentList = '/apartments';
  static const String apartmentDetail = '/apartment-detail';
  static const String editApartment = '/edit-apartment';
  static const String requestList = '/request-list';
  static const String createRequest = '/create-request';
  static const String generateAccessCode = '/manager/generate-code';
  static const String createNotification = '/manager/create-notification';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    residentHome: (context) => const ResidentHomeScreen(),
    adminHome: (context) => const AdminHomeScreen(),
    adminRequests: (context) => const AdminRequestScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    verifyApartment: (context) => const ApartmentVerifyScreen(),
    notifications: (context) => const NotificationsScreen(),
    createInvoice: (context) => const CreateInvoicePage(),
    invoiceList: (_) => const InvoiceListManagementScreen(),

    addApartment: (context) => const AddApartmentScreen(),
    profile: (context) => const ProfileScreen(),
    residentManagement: (context) => const ResidentManagementScreen(),
    bookingRequests: (context) => const BookingRequestsScreen(),
    bookingCalendar: (context) => const BookingCalendarScreen(),
    bookingDetail: (context) {
      final bookingId = ModalRoute.of(context)!.settings.arguments as int;
      return BookingDetailScreen(bookingId: bookingId);
    },
    apartmentList: (context) => const ApartmentListScreen(),
    requestList: (context) => const RequestListScreen(),
    createRequest: (context) => const CreateRequestScreen(),
    apartmentDetail: (context) {
      final id = ModalRoute.of(context)!.settings.arguments as int;
      return ApartmentDetailScreen(apartmentId: id);
    },
    editApartment: (context) {
      final apt =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return EditApartmentScreen(apartmentDetail: apt);
    },

    // bills: (context) => const BillsPage(),
    requestDetailResponse: (context) {
      final request =
          ModalRoute.of(context)!.settings.arguments as RequestModel;
      return RequestDetailResponseScreen(request: request);
    },
    generateAccessCode: (context) => const ManagerGenerateAccessCodeScreen(),
    createNotification: (context) => const ManagerCreateNotificationScreen(),
  };
}
