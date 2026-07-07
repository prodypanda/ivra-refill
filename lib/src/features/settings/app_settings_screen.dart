import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';


class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  static const route = '/app-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final percentageRefillEnabled = ref.watch(percentageRefillEnabledProvider);
    final selectedHotelId = ref.watch(selectedHotelIdProvider);
    final hotels = ref.watch(hotelsProvider).valueOrNull ?? [];

    if (selectedHotelId == null && hotels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHotelIdProvider.notifier).state = hotels.first.id;
      });
    }

    return PageScaffold(
      title: l10n.t('appSettings'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hotels.isNotEmpty) ...[
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.t('hotels'),
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: InputBorder.none,
                    ),
                    value: selectedHotelId,
                    hint: Text(l10n.t('roomsSelectHotelFirst')),
                    isExpanded: true,
                    items: [
                      for (final hotel in hotels)
                        DropdownMenuItem(
                          value: hotel.id,
                          child: Text(
                            hotel.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedHotelIdProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                onChanged: selectedHotelId == null
                    ? null
                    : (value) async {
                        // 1. Optimistic Update
                        ref.read(expressQrEnabledOverrideProvider.notifier).update((state) {
                          return {...state, selectedHotelId: value};
                        });

                        try {
                          await ref.read(repositoryProvider).updateHotelExpressQrEnabled(
                            hotelId: selectedHotelId,
                            enabled: value,
                          );
                          ref.invalidate(hotelsProvider);
                        } catch (e) {
                          // 2. Revert on Error
                          ref.read(expressQrEnabledOverrideProvider.notifier).update((state) {
                            final newState = Map<String, bool>.from(state);
                            newState.remove(selectedHotelId);
                            return newState;
                          });
                          if (context.mounted) {
                            PremiumSnackbar.showError(context, e);
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
