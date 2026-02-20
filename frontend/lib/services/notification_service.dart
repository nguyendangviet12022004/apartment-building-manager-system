import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;
  bool _isListenerSetup = false;

  Future<String?> initialize() async {
    if (_isInitialized) {
      // Return existing token if already initialized
      return await _fcm.getToken();
    }

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // 2. Setup Foreground Listener
      _setupForegroundListener();

      // 3. Get Token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      // send token to backend

      _isInitialized = true;
      return token;
    } else {
      print('User declined or has not accepted permission');
      return null;
    }
  }

  void _setupForegroundListener() {
    if (_isListenerSetup) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("========================================");
      print("RECEIVED FOREGROUND MESSAGE");
      if (message.notification != null) {
        print("TITLE: ${message.notification?.title}");
        print("BODY: ${message.notification?.body}");
      } else {
        print("NOTIFICATION: NULL (Data-only message)");
      }
      print("DATA: ${message.data}");
      print("========================================");
    });

    _isListenerSetup = true;
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    // send request to backend to delete token
    _isInitialized = false;
    _isListenerSetup = false; // Reset listener setup status
    print('FCM Token deleted');
  }
}
