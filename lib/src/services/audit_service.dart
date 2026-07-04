import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/app_state.dart';

class AuditService {
  final SupabaseClient? _supabase;
  String? _deviceInfoCache;

  AuditService(this._supabase);

  Future<String> _getDeviceInfo() async {
    if (_deviceInfoCache != null) return _deviceInfoCache!;

    final deviceInfoPlugin = DeviceInfoPlugin();
    String info = 'Unknown Device';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        info = 'Web (${webInfo.browserName.name} ${webInfo.appVersion ?? ''})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        info = 'Android ${androidInfo.version.release} (${androidInfo.manufacturer} ${androidInfo.model})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        info = 'iOS ${iosInfo.systemVersion} (${iosInfo.name} ${iosInfo.model})';
      }
    } catch (e) {
      info = 'Error getting device info: $e';
    }

    _deviceInfoCache = info;
    return info;
  }

  /// Records an audit entry for [action].
  ///
  /// Returns `true` when the entry was persisted and `false` when it failed.
  /// Audit logging is best-effort and must never disrupt user flows, so
  /// failures are caught and reported (via [debugPrint]) rather than rethrown.
  /// Callers should `await` this so the failure path runs deterministically
  /// instead of being orphaned as an unhandled async error.
  Future<bool> logAction(String action, {Map<String, dynamic>? details}) async {
    if (_supabase == null) {
      debugPrint('Audit Log (Mock): $action');
      return true;
    }

    try {
      final deviceInfo = await _getDeviceInfo();

      await _supabase.rpc(
        'log_audit_action',
        params: {
          'p_action': action,
          'p_details': details ?? {},
          'p_device_info': deviceInfo,
        },
      );
      debugPrint('Audit Log: $action');
      return true;
    } catch (e, stackTrace) {
      // Best-effort: never disrupt the user flow because audit logging failed,
      // but make sure the failure is always visible in logs.
      debugPrint('Failed to log audit action "$action": $e');
      debugPrintStack(stackTrace: stackTrace, label: 'AuditService.logAction');
      return false;
    }
  }
}

final auditServiceProvider = Provider<AuditService>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  return AuditService(useSupabase ? Supabase.instance.client : null);
});
