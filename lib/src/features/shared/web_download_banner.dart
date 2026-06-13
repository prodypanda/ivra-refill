import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class WebDownloadBanner extends ConsumerWidget {
  const WebDownloadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    final isCollapsed = ref.watch(downloadBannerCollapsedProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (isCollapsed) {
      return InkWell(
        onTap: () {
          ref.read(downloadBannerCollapsedProvider.notifier).setCollapsed(false);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.android_rounded,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('downloadAppBannerButton'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.android_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.t('downloadAppBannerText'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://github.com/prodypanda/ivra-refill/releases/latest/download/iVRA_Refill.apk');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.t('downloadAppBannerButton')),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                hoverColor: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                onPressed: () {
                  ref.read(downloadBannerCollapsedProvider.notifier).setCollapsed(true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
