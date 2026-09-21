import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../app/theme.dart';
import '../shared/page_scaffold.dart';
import '../shared/premium_snackbar.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  static const route = '/app-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeExt = theme.extension<IvraThemeExtension>();
    final isBotanical = themeExt?.isBotanical ?? false;
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
            // 1. Awwwards-Level Global Theme & Visual Style Section
            const ThemeSelectorSection(),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 24),

            // 2. Hotel Selection
            if (hotels.isNotEmpty) ...[
              Card(
                elevation: isMobile ? 0 : null,
                shape: isMobile
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            themeExt?.cardBorderRadius ?? 24.0),
                        side: BorderSide(
                          color: isBotanical
                              ? (themeExt?.cardBorderColor ??
                                  theme.colorScheme.outlineVariant)
                              : theme.colorScheme.outlineVariant,
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

            // 3. Percentage Refill Feature Toggle
            Card(
              elevation: isMobile ? 0 : null,
              shape: isMobile
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          themeExt?.cardBorderRadius ?? 24.0),
                      side: BorderSide(
                        color: isBotanical
                            ? (themeExt?.cardBorderColor ??
                                theme.colorScheme.outlineVariant)
                            : theme.colorScheme.outlineVariant,
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

            // 4. Express QR Feature Toggle
            Card(
              elevation: isMobile ? 0 : null,
              shape: isMobile
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          themeExt?.cardBorderRadius ?? 24.0),
                      side: BorderSide(
                        color: isBotanical
                            ? (themeExt?.cardBorderColor ??
                                theme.colorScheme.outlineVariant)
                            : theme.colorScheme.outlineVariant,
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

class ThemeSelectorSection extends ConsumerWidget {
  const ThemeSelectorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentStyle = ref.watch(appThemeStyleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('appThemeStyle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('appThemeStyleSubtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final cards = [
              _ThemeOptionCard(
                style: AppThemeStyle.solarInfusion,
                title: l10n.t('themeSolarInfusion'),
                description: l10n.t('themeSolarInfusionDesc'),
                isSelected: currentStyle == AppThemeStyle.solarInfusion,
                accentColor: const Color(0xFFF59E0B),
                previewGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8F5), Color(0xFFFFF4D9)],
                ),
                buttonColor: const Color(0xFFF59E0B),
                badgeColor: const Color(0xFF855300),
                onTap: () => _selectTheme(context, ref, AppThemeStyle.solarInfusion, l10n.t('themeSolarInfusion')),
              ),
              _ThemeOptionCard(
                style: AppThemeStyle.botanicalHaute,
                title: l10n.t('themeBotanicalHaute'),
                description: l10n.t('themeBotanicalHauteDesc'),
                isSelected: currentStyle == AppThemeStyle.botanicalHaute,
                accentColor: const Color(0xFF10B981),
                previewGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6FBF8), Color(0xFFE5F5ED)],
                ),
                buttonColor: const Color(0xFF10B981),
                badgeColor: const Color(0xFF064E3B),
                onTap: () => _selectTheme(context, ref, AppThemeStyle.botanicalHaute, l10n.t('themeBotanicalHaute')),
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 14),
                  cards[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  void _selectTheme(BuildContext context, WidgetRef ref, AppThemeStyle style, String name) {
    ref.read(appThemeStyleProvider.notifier).setStyle(style);
    final l10n = AppLocalizations.of(context);
    PremiumSnackbar.showSuccess(
      context,
      l10n.tParams('themeSwitchSuccess', {'themeName': name}),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.style,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.accentColor,
    required this.previewGradient,
    required this.buttonColor,
    required this.badgeColor,
    required this.onTap,
  });

  final AppThemeStyle style;
  final String title;
  final String description;
  final bool isSelected;
  final Color accentColor;
  final LinearGradient previewGradient;
  final Color buttonColor;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBotanicalOption = style == AppThemeStyle.botanicalHaute;
    final cardRadius = isBotanicalOption ? 12.0 : 22.0;
    final buttonRadius = isBotanicalOption ? 4.0 : 20.0;
    final badgeRadius = isBotanicalOption ? 3.0 : 10.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        splashColor: accentColor.withValues(alpha: 0.15),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: isSelected ? accentColor : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Swatch Visual Preview Banner
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: previewGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius - 2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(badgeRadius),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Text(
                              'IVRA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: isBotanicalOption ? 1.4 : 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isBotanicalOption ? 12 : 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              borderRadius: BorderRadius.circular(buttonRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: buttonColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              isBotanicalOption ? 'REFILL 500ML' : 'Refill 500ml',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: isBotanicalOption ? 10 : 11,
                                letterSpacing: isBotanicalOption ? 1.2 : 0.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: accentColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.t('themeActive'),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
