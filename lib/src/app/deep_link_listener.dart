import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routing/app_router.dart';

/// Bridges `ivra://app/...` deep links into go_router after the app is
/// already running.
///
/// `AndroidManifest.xml`'s `flutter_deeplinking_enabled=true` covers the
/// cold-start case: the OS launches the activity with an intent whose
/// data URI becomes go_router's initial location. That path does not,
/// however, deliver subsequent intents (e.g. the user has the app open,
/// taps a password-reset link in their email, the activity receives
/// `onNewIntent`) reliably across Flutter engine versions.
///
/// `app_links` provides a stable platform-channel stream that fires for
/// both the initial URI and any new intents the activity receives.
/// Subscribing here and forwarding parsed URIs to `routerProvider`
/// guarantees the hot-state case lands on the right screen with its
/// query parameters intact.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AppLinks().uriLinkStream.listen(
      _handleUri,
      onError: (_) {
        // A failed deep-link delivery must never crash the app. The user
        // can still navigate manually if the OS swallowed the intent.
      },
    );
  }

  void _handleUri(Uri uri) {
    if (!mounted) return;
    if (uri.scheme != 'ivra' || uri.host != 'app') return;

    final path = uri.path.isEmpty ? '/' : uri.path;
    final target = uri.queryParameters.isEmpty
        ? path
        : Uri(path: path, queryParameters: uri.queryParameters).toString();

    ref.read(routerProvider).go(target);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
