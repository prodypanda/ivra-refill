import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditService {
  final SupabaseClient _supabase;
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

  Future<void> logAction(String action, {Map<String, dynamic>? details}) async {
    try {
      // We do not await this heavily to avoid slowing down the UI
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
    } catch (e) {
      debugPrint('Failed to log audit action: $e');
      // Silently fail so we don't disrupt user flows on audit logging errors
    }
  }
}

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(Supabase.instance.client);
});
