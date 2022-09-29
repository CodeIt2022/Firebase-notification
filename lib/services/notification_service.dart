// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_app/main.dart';
import 'package:notification_app/screen/web_view_screen/web_view_screen.dart';

class NotificationService {
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    logs('Background message --> ${message.toMap()}');
    await Firebase.initializeApp();
    await initializeLocalNotification();
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => const WebViewScreen()),
    );
  }

  //     ======================= Generate FCM Token =======================     //
  static Future<String?> generateFCMToken() async {
    try {
      String? token = await firebaseMessaging.getToken();
      logs('Firebase FCM Token --> $token');
      return token;
    } on FirebaseException catch (e) {
      logs('Catch error in generateFCMToken --> ${e.message}');
      return null;
    }
  }

  static Future<void> initializeNotification() async {
    await Firebase.initializeApp();
    await initializeLocalNotification();
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    await generateFCMToken();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
      logs('Remote messages in onMessage --> ${remoteMessage.toMap()}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
      logs('Remote messages in onMessageOpenedApp --> ${remoteMessage.toMap()}');
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
    });

    NotificationSettings notificationSettings = await firebaseMessaging.requestPermission(announcement: true);

    logs('Notification permission status : ${notificationSettings.authorizationStatus.name}');

    if (notificationSettings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) async {
        logs('Message title: ${remoteMessage.notification!.title}, body: ${remoteMessage.notification!.body}');

        await flutterLocalNotificationsPlugin.show(
          0,
          remoteMessage.notification!.title!,
          remoteMessage.notification!.body!,
          notificationDetails,
        );
      });
    }
  }

  static initializeLocalNotification() {
    AndroidInitializationSettings androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings darwinInitializationSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    InitializationSettings platform = InitializationSettings(android: androidInitializationSettings, iOS: darwinInitializationSettings);
    flutterLocalNotificationsPlugin.initialize(platform);
  }

  static AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails(
    'CHANNEL ID',
    'CHANNEL NAME',
    channelDescription: 'CHANNEL DESCRIPTION',
    importance: Importance.max,
    priority: Priority.max,
  );
  static DarwinNotificationDetails darwinNotificationDetails = const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  static NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: darwinNotificationDetails);
}
