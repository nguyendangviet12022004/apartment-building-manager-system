import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification == null && message.data.isEmpty) {
    return;
  }

  print("========================================");
  print("RECEIVED BACKGROUND MESSAGE");
  if (message.notification != null) {
    print("TITLE: ${message.notification?.title}");
    print("BODY: ${message.notification?.body}");
  } else {
    print("NOTIFICATION: NULL (Data-only message)");
  }
  print("DATA: ${message.data}");
  print("========================================");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'Apartment Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          // Check auth status here
          initialRoute: authProvider.isAuthenticated
              ? (authProvider.role == 'RESIDENT'
                    ? AppRoutes.residentHome
                    : (authProvider.role == 'ADMIN' ||
                          authProvider.role == 'MANAGER')
                    ? AppRoutes.adminHome
                    : AppRoutes.home)
              : AppRoutes.login,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
