import 'dart:io';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../app/ivra_app.dart';
import '../state/app_state.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background tap
  debugPrint('notificationTapBackground: ${notificationResponse.actionId}');
}

final notificationServiceProvider = Provider((ref) {
  return NotificationService(Supabase.instance.client);
});

class NotificationService {
  NotificationService(this._supabase);

  final SupabaseClient _supabase;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push notification permission');
      await _registerToken();
      _fcm.onTokenRefresh.listen((_) => _registerToken());
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationAction(response.payload, response.actionId);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create default channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel_v2',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      NotificationService.showLocalNotification(message);
    });
  }

  void _handleNotificationAction(String? payloadStr, String? actionId) {
    if (payloadStr == null) return;
    try {
      final payload = jsonDecode(payloadStr);
      final context = scaffoldMessengerKey.currentContext;
      
      if (actionId == 'Dismiss') {
        return;
      }
      
      if (context != null) {
        if (actionId == 'Acknowledge') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acknowledged')));
        }
        
        final targetPage = payload['targetPage'];
        if (targetPage != null && targetPage.toString().isNotEmpty) {
           GoRouter.of(context).go(targetPage.toString());
        }
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final title = data['title'] ?? message.notification?.title ?? 'New Notification';
    final body = data['body'] ?? message.notification?.body ?? '';
    final actionButtonsStr = data['actionButtons'];
    
    List<AndroidNotificationAction> actions = [];
    if (actionButtonsStr != null && actionButtonsStr.isNotEmpty) {
      try {
        final List<dynamic> btns = jsonDecode(actionButtonsStr);
        for (var btn in btns) {
          actions.add(AndroidNotificationAction(
            btn.toString(),
            btn.toString(),
            showsUserInterface: true,
          ));
        }
      } catch (e) {
        debugPrint('Error parsing actionButtons: $e');
      }
    }
    
    final payload = jsonEncode(data);

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel_v2',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: actions,
      playSound: true,
    );
    
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id: message.messageId.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      String deviceType = 'web';
      if (!kIsWeb) {
        if (Platform.isAndroid) deviceType = 'android';
        else if (Platform.isIOS) deviceType = 'ios';
      }

      await _supabase.rpc('register_fcm_token', params: {
        'p_token': token,
        'p_device_type': deviceType,
      });
      debugPrint('FCM Token registered successfully.');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }
}
