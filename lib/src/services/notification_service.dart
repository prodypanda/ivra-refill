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
import '../l10n/app_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background tap
  debugPrint('notificationTapBackground: ${notificationResponse.actionId}');
}

final notificationServiceProvider = Provider((ref) {
  return NotificationService(Supabase.instance.client, ref);
});

class NotificationService {
  NotificationService(this._supabase, this._ref);

  final SupabaseClient _supabase;
  final Ref _ref;
  FirebaseMessaging? _fcm;

  static NotificationResponse? _pendingNotificationResponse;

  void _checkAndProcessPending() {
    final response = _pendingNotificationResponse;
    if (response == null) return;

    final context = scaffoldMessengerKey.currentContext;
    if (context != null) {
      _pendingNotificationResponse = null;
      _handleNotificationAction(response.payload, response.actionId);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndProcessPending();
      });
    }
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _pendingNotificationResponse = response;
        _checkAndProcessPending();
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create default channel and request local permissions
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel_v2',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );
      
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.requestNotificationsPermission();
    }

    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
         debugPrint('FCM not supported on this desktop platform natively.');
         return;
      }
      
      _fcm = FirebaseMessaging.instance;
      
      final settings = await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted push notification permission');
        await _registerToken();
        _fcm!.onTokenRefresh.listen((_) => _registerToken());
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');
        NotificationService.showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }

    // Check if app was launched from a notification
    try {
      final launchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final response = launchDetails.notificationResponse;
        if (response != null) {
          _pendingNotificationResponse = response;
        }
      }
    } catch (e) {
      debugPrint('Error getting notification launch details: $e');
    }

    _checkAndProcessPending();
  }

  void _handleNotificationAction(String? payloadStr, String? actionId) {
    if (payloadStr == null) return;
    try {
      final payload = jsonDecode(payloadStr);
      final context = scaffoldMessengerKey.currentContext;

      String? alertId = payload['alertId']?.toString();
      String? hotelId = payload['hotelId']?.toString();
      if (payload['data'] != null) {
        try {
          final nestedData = payload['data'] is String ? jsonDecode(payload['data']) : payload['data'];
          if (nestedData is Map) {
            alertId ??= nestedData['alertId']?.toString();
            hotelId ??= nestedData['hotelId']?.toString();
          }
        } catch (_) {}
      }
      
      if (actionId == 'Dismiss') {
        return;
      }
      
      if (context != null) {
        if (actionId == 'Acknowledge') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acknowledged')));
        }
        
        if (actionId == 'more_info') {
          if (hotelId != null && hotelId.isNotEmpty) {
            GoRouter.of(context).go('/inventory?hotelId=$hotelId');
          } else {
            GoRouter.of(context).go('/inventory');
          }
          return;
        }
        
        if (actionId == 'resolve') {
          if (alertId != null && alertId.isNotEmpty) {
            _ref.read(repositoryProvider).resolveAlert(alertId: alertId).then((_) {
              if (!context.mounted) return;
              _ref.invalidate(alertsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).t('alertResolvedToast')),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }).catchError((e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to resolve alert: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            });
          }
          GoRouter.of(context).go('/alerts');
          return;
        }
        
        if (actionId == 'delete') {
          if (alertId != null && alertId.isNotEmpty) {
            _ref.read(repositoryProvider).deleteAlert(alertId).then((_) {
              if (!context.mounted) return;
              _ref.invalidate(alertsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).t('alertDeletedToast')),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }).catchError((e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete alert: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            });
          }
          GoRouter.of(context).go('/alerts');
          return;
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
          if (btn is Map) {
            actions.add(AndroidNotificationAction(
              btn['id'].toString(),
              btn['title'].toString(),
              showsUserInterface: true,
            ));
          } else {
            actions.add(AndroidNotificationAction(
              btn.toString(),
              btn.toString(),
              showsUserInterface: true,
            ));
          }
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
      if (_fcm == null) return;
      final token = await _fcm!.getToken();
      if (token == null) return;

      String deviceType = 'web';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          deviceType = 'android';
        } else if (Platform.isIOS) {
          deviceType = 'ios';
        }
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
