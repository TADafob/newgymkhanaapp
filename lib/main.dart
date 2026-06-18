// main.dart

// for Color
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/core/utils/app_theme.dart';
import 'package:nrbgymkhana/core/utils/connectivityawarewidget.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/widgets/notification_overlay_service.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:nrbgymkhana/features/home/presentation/widgets/theme_provider.dart';
import 'package:nrbgymkhana/firebase_options.dart';
import 'package:nrbgymkhana/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global instance for showing local notifications.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background handler for Firebase Messaging.
/// MUST be a top-level function and annotated with @pragma('vm:entry-point')
/// so it's not stripped during AOT compilation when called from native code.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('🔔 Background message received: ${message.messageId}');

    // Initialize plugin for background context
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings(
          '@drawable/ic_stat_images_removebg_preview',
        );
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(android: initSettingsAndroid),
    );

    final data = message.data;
    String title;
    String body;

    if (data.containsKey('amount') && data.containsKey('is_top_up')) {
      final isTopUp = data['is_top_up'] == '1';
      final amount = data['amount'] ?? '';
      title = isTopUp ? 'Card Top-Up Successful' : 'Card Transaction';
      body = '${isTopUp ? '+' : '-'}Ksh $amount — ${data['trans_Descr'] ?? ''}';
    } else {
      title = message.notification?.title ?? 'New Notification';
      body = message.notification?.body ?? '';
    }

    if (title.isEmpty && body.isEmpty) {
      debugPrint('⚠️ Empty title and body, skipping notification');
      return;
    }

    final isCard = data.containsKey('amount');
    debugPrint('📢 Showing background notification: $title');

    // Show using the channels already registered in main()
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isCard ? 'card_updates' : 'booking_updates',
          isCard ? 'Card Updates' : 'Booking Updates',
          channelDescription:
              isCard
                  ? 'Notifications for card balance changes'
                  : 'Notifications for new bookings',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error in background handler: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure image caching
  final tempDir = await getTemporaryDirectory();
  final cacheManager = CacheManager(
    Config(
      'gymkhana_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(path: tempDir.path),
    ),
  );

  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  // ─── Booking channel ─────────────────────────────────────────────────────────
  const AndroidNotificationChannel bookingChannel = AndroidNotificationChannel(
    'booking_updates', // unified channel ID
    'Booking Updates',
    description: 'High priority booking notifications',
    importance: Importance.max,
  );

  // ─── Card‐update channel ─────────────────────────────────────────────────────
  const AndroidNotificationChannel cardChannel = AndroidNotificationChannel(
    'card_updates',
    'Card Updates',
    description: 'Notifications for card balance changes',
    importance: Importance.max,
  );

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings(
        '@drawable/ic_stat_images_removebg_preview',
      ); // ensure icon exists!
  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        debugPrint('Notification payload: ${response.payload}');
      }
    },
  );

  // Register both channels
  final androidImpl =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidImpl?.createNotificationChannel(bookingChannel);
  await androidImpl?.createNotificationChannel(cardChannel);

  // Request FCM permissions & print token (non-blocking on iOS)
  await _requestFirebaseMessagingPermissions();
  _printDeviceToken(); // intentionally not awaited — getToken() can hang on iOS without APNs

  // Configure EasyLoading
  configLoading();

  // Wrap with ProviderScope and ScreenUtilInit
  runApp(
    ProviderScope(child: NotificationListener(child: const GymkhanaApp())),
  );
}

Future<void> _requestFirebaseMessagingPermissions() async {
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
}

Future<void> _printDeviceToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) print('FCM Token: $token');
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..maskType = EasyLoadingMaskType.black
    ..toastPosition = EasyLoadingToastPosition.bottom
    ..dismissOnTap = false
    ..animationStyle = EasyLoadingAnimationStyle.scale
    ..textColor = Colors.white;

  // Performance optimizations
  CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
}

/// This widget sets up FCM listeners and writes incoming messages to Firestore.
class NotificationListener extends StatefulWidget {
  final Widget child;
  const NotificationListener({super.key, required this.child});

  @override
  _NotificationListenerState createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<NotificationListener> {
  final _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) _saveFCMToken(user.uid);

    // Refresh token whenever FCM rotates it
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final notifEnabled = await LocalStorage.getNotificationsEnabled();
      if (notifEnabled != true) return;
      await FirebaseFirestore.instance
          .collection('users_members')
          .doc(uid)
          .update({'fcm_Token': newToken});
      debugPrint('FCM token refreshed and saved for $uid');
    });
  }

  Future<void> _saveFCMToken(String userId) async {
    try {
      final notifEnabled = await LocalStorage.getNotificationsEnabled();
      if (notifEnabled != true) return;
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users_members')
            .doc(userId)
            .update({'fcm_Token': token});
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) async {
    final notifEnabled = await LocalStorage.getNotificationsEnabled();
    if (notifEnabled != true) return;

    final data = message.data;
    final user = FirebaseAuth.instance.currentUser;

    // ─── Card Update ───────────────────────────────────────────────────────────
    if (data.containsKey('amount') &&
        data.containsKey('trans_Descr') &&
        data.containsKey('is_top_up')) {
      final amount = data['amount'] ?? '0.00';
      final description = data['trans_Descr'] ?? '';
      final isTopUp = data['is_top_up'] == '1';
      final rcptNo = data['receipt_id'] ?? data['rcpt_no'] ?? 'N/A';

      // Show in-app overlay banner
      NotificationOverlayService.show(
        title: isTopUp ? 'Card Top Up' : 'Card Transaction',
        body: '${isTopUp ? '+' : '-'}Ksh $amount — $description',
        icon: Icons.credit_card_rounded,
        isCardUpdate: true,
        isTopUp: isTopUp,
      );

      // Show system heads-up (when app is backgrounded)
      _showCardUpdateNotification(
        amount: amount,
        description: description,
        isTopUp: isTopUp,
      );

      if (user != null) {
        FirebaseFirestore.instance.collection('notifications_collection').add({
          'recipientId': user.uid,
          'title': 'Card Transaction - Receipt $rcptNo',
          'type': 'card_update',
          'amount': amount,
          'description': description,
          'isTopUp': isTopUp,
          'timestamp': Timestamp.now(),
          'isNew': true,
        });
      }
      return;
    }

    // ─── Booking / Fallback ────────────────────────────────────────────────────
    final n = message.notification;
    if (n != null && user != null) {
      // Pick icon based on notification type
      final type = data['type'] as String? ?? '';
      final IconData icon;
      final Color iconColor;
      switch (type) {
        case 'booking_reminder':
          icon = Icons.alarm_rounded;
          iconColor = Colors.orange;
          break;
        case 'payment_reminder':
          icon = Icons.payment_rounded;
          iconColor = Colors.deepOrange;
          break;
        case 'subscription_reminder':
          icon = Icons.card_membership_rounded;
          iconColor = Colors.purple;
          break;
        default:
          icon = Icons.event_available_rounded;
          iconColor = const Color(0xFF0693e3);
      }

      // Check sub-toggles
      final prefs = await SharedPreferences.getInstance();
      if (type == 'booking_reminder' || type == 'payment_reminder') {
        if (prefs.getBool('booking_reminders') == false) return;
      } else if (type == 'subscription_reminder') {
        if (prefs.getBool('news_alerts') == false) return;
      }

      // Show in-app overlay banner
      NotificationOverlayService.show(
        title: n.title ?? 'New Notification',
        body: n.body ?? '',
        icon: icon,
        iconColor: iconColor,
      );

      _showLocalNotification(n.title ?? 'New Notification', n.body ?? '');
      FirebaseFirestore.instance.collection('notifications_collection').add({
        'recipientId': user.uid,
        'type': type.isEmpty ? 'booking' : type,
        'title': n.title ?? 'No Title',
        'description': n.body ?? 'No Description',
        'timestamp': Timestamp.now(),
        'isNew': true,
      });
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_updates', // must match the one above
      'Booking Updates',
      channelDescription: 'Notifications for new bookings',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      details,
      payload: 'NotificationPayload',
    );
  }

  /// New helper for styled card‐balance notifications
  Future<void> _showCardUpdateNotification({
    required String amount,
    required String description,
    required bool isTopUp,
  }) async {
    final color =
        isTopUp
            ? const Color(0xFF00C853) // Green for top-up
            : const Color(0xFFD50000); // Red for charge

    final androidDetails = AndroidNotificationDetails(
      'card_updates',
      'Card Updates',
      channelDescription: 'Balance changes',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        description,
        htmlFormatBigText: false,
        contentTitle: amount, // Bold text in collapsed view
        summaryText: 'Tap to view details',
      ),
      color: color,
      colorized: true,
      enableLights: true,
      ledColor: color,
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "${isTopUp ? '+' : '-'}$amount", // Show + for top-up and - for charge
      description, // Full description in expanded view
      details,
      payload: 'card_updates',
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The root widget for your app.
class GymkhanaApp extends ConsumerWidget {
  const GymkhanaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Nairobi Gymkhana',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          builder: (context, child) {
            // 1️⃣ wrap with EasyLoading
            final withLoading = EasyLoading.init()(context, child);

            // 2️⃣ wrap with connectivity overlay
            return ConnectivityAwareWidget(child: withLoading);
          },
        );
      },
    );
  }
}
