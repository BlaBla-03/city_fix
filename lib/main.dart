import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/incident_chat_screen.dart';
import 'screens/incident_details_screen.dart';
import 'utils/permissions.dart';
import 'utils/auth_service.dart';
import 'utils/location_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  await AppPermissions.requestAllPermissions(); // Request permissions
  await LocationService.initializeLocation(); // Initialize location

  // Request notification permissions (iOS & Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create a notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Set up foreground notification handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _getInitialScreen();
    _setupNotificationTapHandler();
  }

  void _setupNotificationTapHandler() {
    // Handle when app is opened from a notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message);
    });
    // Handle when app is launched from a terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });
  }

  void _handleNotificationNavigation(RemoteMessage message) async {
    final data = message.data;
    final reportId = data['reportId'];
    final isChat = data['chat'] == 'true';
    if (reportId == null) return;
    // Fetch report data from Firestore
    final doc =
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .get();
    if (!doc.exists) return;
    final reportData = doc.data()!;
    // Use navigatorKey to access context
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (isChat) {
      navigator.push(
        MaterialPageRoute(
          builder:
              (context) => IncidentChatScreen(
                reportId: reportId,
                reportData: reportData,
              ),
        ),
      );
    } else {
      navigator.push(
        MaterialPageRoute(
          builder:
              (context) => IncidentDetailsScreen(
                reportId: reportId,
                reportData: reportData,
              ),
        ),
      );
    }
  }

  Future<Widget> _getInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      return const WelcomeScreen();
    }

    final user = FirebaseAuth.instance.currentUser;

    // Bring any logged-in (non-anonymous) user to home screen
    if (user != null && !user.isAnonymous) {
      return HomeScreen.protected();
    }

    return const LoginRegistrationScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CityFix',
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          primary: AppTheme.primaryColor,
          secondary: AppTheme.secondaryColor,
          background: AppTheme.backgroundColor,
          error: AppTheme.errorColor,
          surface: AppTheme.surfaceColor,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        appBarTheme: AppTheme.appBarTheme,
        textTheme: TextTheme(
          headlineLarge: AppTheme.headingStyle,
          headlineMedium: AppTheme.subheadingStyle,
          bodyLarge: AppTheme.bodyStyle,
          bodyMedium: AppTheme.captionStyle,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: FutureBuilder<Widget>(
        future: _initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }
          return snapshot.data ?? const LoginRegistrationScreen();
        },
      ),
    );
  }
}
