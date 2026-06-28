import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models.dart';
import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/product_image.dart';
import '../shared/glass_card.dart';

class PublicProductScreen extends ConsumerWidget {
  const PublicProductScreen({super.key, required this.sku});

  final String sku;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              theme.colorScheme.surface,
              theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                      tooltip: l10n.t('btnBack'),
                    ),
                    Image.asset(
                      'assets/logo.png',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'IVRA COSMETICS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
              ),
              Expanded(
                child: AsyncValueView<List<Product>>(
                  value: productsAsync,
                  onRetry: () => ref.invalidate(productsProvider),
                  builder: (products) {
                    final product = products.cast<Product?>().firstWhere(
                          (p) => p?.sku.toLowerCase() == sku.toLowerCase(),
                          orElse: () => null,
                        );

                    if (product == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.t('productNotFound') ?? 'Product Not Found',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SKU: $sku',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.go('/login'),
                              child: Text(l10n.t('loginTitle')),
                            ),
                          ],
                        ),
                      );
                    }

                    final productName = product.label(language);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Hero(
                              tag: 'product-${product.id}',
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.shadowColor.withValues(alpha: 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: ProductImage(
                                    imagePath: product.imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.sku,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  productName,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'IVRA COSMETICS • PREMIUM ECO Refill',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Divider(color: theme.dividerColor),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.t('productDetails') ?? 'Product Specifications',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildSpecRow(
                                  context,
                                  icon: Icons.local_drink_outlined,
                                  label: l10n.t('productLabelVolume') ?? 'Bottle Volume',
                                  value: '${product.bottleVolumeMl} ml',
                                ),
                                _buildSpecRow(
                                  context,
                                  icon: Icons.science_outlined,
                                  label: l10n.t('productLabelBidonVolume') ?? 'Refill Bidon Size',
                                  value: '${product.bidonVolumeMl} ml',
                                ),
                                _buildSpecRow(
                                  context,
                                  icon: product.bottleType == BottleType.withPump
                                      ? Icons.sanitizer_outlined
                                      : Icons.opacity,
                                  label: l10n.t('productLabelBottleType') ?? 'Dispenser Type',
                                  value: product.bottleType == BottleType.withPump
                                      ? (l10n.t('productBottleTypeWithPump') ?? 'With Pump')
                                      : (l10n.t('productBottleTypeWithoutPump') ?? 'Without Pump'),
                                ),
                                _buildSpecRow(
                                  context,
                                  icon: Icons.autorenew_outlined,
                                  label: l10n.t('productLabelRefillType') ?? 'System Type',
                                  value: product.isRefillable
                                      ? (l10n.t('productRefillTypeRefillable') ?? 'Refillable')
                                      : (l10n.t('productRefillTypeDirectReplacement') ?? 'Direct Replacement'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Environmental benefits card
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.eco_outlined,
                                    color: Colors.green.shade700,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.t('ecoFriendlyTitle') ?? 'Sustainable Luxury',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.t('ecoFriendlyDesc') ??
                                            'By refilling dispensers, this hotel prevents plastic waste and preserves our planet\'s natural beauty.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
