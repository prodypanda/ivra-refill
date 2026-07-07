import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/page_scaffold.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  static const route = '/app-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final percentageRefillEnabled = ref.watch(percentageRefillEnabledProvider);

    return PageScaffold(
      title: l10n.t('appSettings'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: isMobile ? 0 : null,
              shape: isMobile
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    )
                  : null,
              child: SwitchListTile(
                secondary: const Icon(Icons.percent_outlined),
                title: Text(l10n.t('percentageRefillTitle')),
                subtitle: Text(l10n.t('percentageRefillSubtitle')),
                value: percentageRefillEnabled,
                onChanged: (value) {
                  ref.read(percentageRefillEnabledProvider.notifier).state = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: isMobile ? 0 : null,
              shape: isMobile
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    )
                  : null,
              child: SwitchListTile(
                secondary: const Icon(Icons.qr_code_scanner_outlined),
                title: Text(l10n.t('expressQrTitle')),
                subtitle: Text(l10n.t('expressQrSubtitle')),
                value: ref.watch(expressQrEnabledProvider),
                onChanged: (value) {
                  ref.read(expressQrEnabledProvider.notifier).state = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
