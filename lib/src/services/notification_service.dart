import 'dart:io';
import 'dart:async';
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

/// A toast that should be shown to the user as soon as a [BuildContext] backed
/// by [scaffoldMessengerKey] is available. Used to surface the outcome of a
/// notification action (resolve/delete) that may have been triggered before any
/// UI was mounted (cold start).
class _PendingToast {
  const _PendingToast({required this.messageKey, required this.isError});

  /// Localization key resolved against [AppLocalizations]. If the key is
  /// unknown, [AppLocalizations.t] returns the key itself, which is still safe
  /// to display.
  final String messageKey;
  final bool isError;
}

class NotificationService {
  NotificationService(this._supabase, this._ref);

  final SupabaseClient? _supabase;
  final Ref _ref;
  FirebaseMessaging? _fcm;

  /// The notification that launched the app from a terminated state, or a tap
  /// received before the app finished building its first frame. Held until the
  /// app is ready to act on it.
  NotificationResponse? _pendingNotificationResponse;

  /// Outcome toasts waiting for a usable [BuildContext].
  final List<_PendingToast> _pendingToasts = <_PendingToast>[];

  /// Route to navigate to once a context/router is available.
  String? _pendingNavigation;

  /// Bounds the post-frame retry loop so a missing context can never spin
  /// forever (e.g. user dismisses the launch before any screen mounts).
  static const int _maxContextRetries = 50; // ~ up to a few seconds of frames
  int _contextRetries = 0;
  bool _drainScheduled = false;

  BuildContext? get _messengerContext => scaffoldMessengerKey.currentContext;

  void _scheduleDrain() {
    if (_drainScheduled) return;
    _drainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainScheduled = false;
      _drainPending();
    });
  }

  /// Processes any deferred notification response, navigation, and toasts.
  /// Safe to call repeatedly. The data side of an action (resolve/delete RPC)
  /// runs immediately and does not wait for a context; only the user-facing
  /// toast and navigation are deferred until the UI is ready.
  void _drainPending() {
    final response = _pendingNotificationResponse;
    if (response != null) {
      _pendingNotificationResponse = null;
      _handleNotificationAction(response.payload, response.actionId);
    }

    final context = _messengerContext;

    if (context == null) {
      // Nothing can be shown/navigated yet. Retry on the next frame, bounded.
      if ((_pendingToasts.isNotEmpty || _pendingNavigation != null) &&
          _contextRetries < _maxContextRetries) {
        _contextRetries++;
        _scheduleDrain();
      }
      return;
    }

    _contextRetries = 0;

    // Flush queued toasts.
    if (_pendingToasts.isNotEmpty) {
      final toasts = List<_PendingToast>.from(_pendingToasts);
      _pendingToasts.clear();
      final l10n = AppLocalizations.of(context);
      for (final toast in toasts) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t(toast.messageKey)),
            backgroundColor:
                toast.isError ? Colors.red : const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Flush deferred navigation.
    final navigation = _pendingNavigation;
    if (navigation != null) {
      _pendingNavigation = null;
      GoRouter.of(context).go(navigation);
    }
  }

  void _queueToast(String messageKey, {required bool isError}) {
    _pendingToasts.add(_PendingToast(messageKey: messageKey, isError: isError));
    _scheduleDrain();
  }

  void _queueNavigation(String location) {
    _pendingNavigation = location;
    _scheduleDrain();
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
        _drainPending();
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

    _drainPending();
  }

  void _handleNotificationAction(String? payloadStr, String? actionId) {
    if (payloadStr == null) return;
    try {
      final payload = jsonDecode(payloadStr);

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

      if (actionId == 'Acknowledge') {
        _queueToast('notificationAcknowledgedToast', isError: false);
        return;
      }

      if (actionId == 'more_info') {
        if (hotelId != null && hotelId.isNotEmpty) {
          _queueNavigation('/inventory?hotelId=$hotelId');
        } else {
          _queueNavigation('/inventory');
        }
        return;
      }

      if (actionId == 'resolve') {
        if (alertId != null && alertId.isNotEmpty) {
          _runAlertMutation(
            action: _ref.read(repositoryProvider).resolveAlert(alertId: alertId),
            successKey: 'alertResolvedToast',
            failureKey: 'alertResolveFailedToast',
          );
        }
        _queueNavigation('/alerts');
        return;
      }

      if (actionId == 'delete') {
        if (alertId != null && alertId.isNotEmpty) {
          _runAlertMutation(
            action: _ref.read(repositoryProvider).deleteAlert(alertId),
            successKey: 'alertDeletedToast',
            failureKey: 'alertDeleteFailedToast',
          );
        }
        _queueNavigation('/alerts');
        return;
      }

      final targetPage = payload['targetPage'];
      if (targetPage != null && targetPage.toString().isNotEmpty) {
        _queueNavigation(targetPage.toString());
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  /// Runs an alert mutation (resolve/delete) without requiring a live
  /// [BuildContext]. The repository call and provider invalidation happen
  /// immediately; the success/failure toast is queued and surfaced as soon as
  /// the UI is ready, so the result is never silently dropped on cold start.
  void _runAlertMutation({
    required Future<void> action,
    required String successKey,
    required String failureKey,
  }) {
    action.then((_) {
      _ref.invalidate(alertsProvider);
      _queueToast(successKey, isError: false);
    }).catchError((Object e) {
      debugPrint('Notification alert mutation failed: $e');
      _queueToast(failureKey, isError: true);
    });
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

      if (_supabase == null) {
        debugPrint('SupabaseClient is null, skipping token registration.');
        return;
      }
      await _supabase!.rpc('register_fcm_token', params: {
        'p_token': token,
        'p_device_type': deviceType,
      });
      debugPrint('FCM Token registered successfully.');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }
}
