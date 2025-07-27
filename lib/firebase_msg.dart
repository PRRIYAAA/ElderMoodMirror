import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
FirebaseAnalytics analytics = FirebaseAnalytics.instance;
class FirebaseMsg {
  final _messaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initFCM() async {
    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    print("FCM Token: $token");

    // Local notifications config
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      _showNotification(message);
    });

    // Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }
}
