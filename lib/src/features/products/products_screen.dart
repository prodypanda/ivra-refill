import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  static const route = '/products';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.t('productsCatalogTitle'),
      actions: [
        IconButton(
          tooltip: l10n.t('productsBtnCreate'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showProductDialog(context, ref),
        ),
      ],
      child: AsyncValueView(
        value: ref.watch(productsProvider),
        builder: (products) => _ProductsTable(products: products),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    WidgetRef ref, {
    Product? product,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ProductDialog(product: product),
    );

    ref.invalidate(productsProvider);
    ref.invalidate(roomProductsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(suggestedOrdersProvider);
    ref.invalidate(dashboardProvider);
  }
}

class _ProductsTable extends ConsumerWidget {
  const _ProductsTable({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);

    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.t('productsNoProducts')),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        final spacing = constraints.maxWidth < 420 ? 12.0 : 20.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              SizedBox(
                width: cardWidth.clamp(0, 360).toDouble(),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                product.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0C4A3A),
                                        Color(0xFF267D65),
                                        Color(0xFF3EA47E),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.spa_outlined,
                                          size: 48,
                                          color: Colors.white
                                              .withValues(alpha: 0.95),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product.sku,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.sku,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.label(language),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            _RuleRow(
                                Icons.pin_drop_outlined,
                                l10n.t('productsLabelBottleVolume'),
                                '${product.bottleVolumeMl} ml'),
                            _RuleRow(
                                Icons.propane_tank_outlined,
                                l10n.t('productsLabelBidonVolume'),
                                '${product.bidonVolumeMl} ml'),
                            _RuleRow(
                                Icons.loop_outlined,
                                l10n.t('productsLabelMaxRefill'),
                                '${product.maxRefillCount} ${l10n.t('refills')}'),
                            _RuleRow(
                                Icons.calendar_today_outlined,
                                l10n.t('productsLabelMaxAge'),
                                '${product.maxBottleAgeDays} ${l10n.t('days')}'),
                            _RuleRow(
                              Icons.warning_amber_outlined,
                              l10n.t('productsLabelLowStock'),
                              '${product.lowBottleThreshold} ${l10n.t('bottles').toLowerCase()} / ${product.lowBidonThreshold} ${l10n.t('bidons').toLowerCase()}',
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(
                                      l10n.t('productsBtnEdit'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (context) =>
                                          _ProductDialog(product: product),
                                    ).then((_) {
                                      ref.invalidate(productsProvider);
                                      ref.invalidate(roomProductsProvider);
                                      ref.invalidate(inventoryProvider);
                                      ref.invalidate(suggestedOrdersProvider);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sku;
  late final TextEditingController _nameEn;
  late final TextEditingController _nameFr;
  late final TextEditingController _nameAr;
  late final TextEditingController _nameIt;
  late final TextEditingController _bottleVolumeMl;
  late final TextEditingController _bidonVolumeMl;
  late final TextEditingController _maxRefillCount;
  late final TextEditingController _maxBottleAgeDays;
  late final TextEditingController _lowBottleThreshold;
  late final TextEditingController _lowBidonThreshold;
  late final TextEditingController _imageUrl;
  var _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _sku = TextEditingController(text: product?.sku ?? '');
    _nameEn = TextEditingController(text: product?.nameEn ?? '');
    _nameFr = TextEditingController(text: product?.nameFr ?? '');
    _nameAr = TextEditingController(text: product?.nameAr ?? '');
    _nameIt = TextEditingController(text: product?.nameIt ?? '');
    _bottleVolumeMl = TextEditingController(
      text: '${product?.bottleVolumeMl ?? 1000}',
    );
    _bidonVolumeMl = TextEditingController(
      text: '${product?.bidonVolumeMl ?? 5000}',
    );
    _maxRefillCount = TextEditingController(
      text: '${product?.maxRefillCount ?? 10}',
    );
    _maxBottleAgeDays = TextEditingController(
      text: '${product?.maxBottleAgeDays ?? 240}',
    );
    _lowBottleThreshold = TextEditingController(
      text: '${product?.lowBottleThreshold ?? 12}',
    );
    _lowBidonThreshold = TextEditingController(
      text: '${product?.lowBidonThreshold ?? 4}',
    );
    _imageUrl = TextEditingController(text: product?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _sku.dispose();
    _nameEn.dispose();
    _nameFr.dispose();
    _nameAr.dispose();
    _nameIt.dispose();
    _bottleVolumeMl.dispose();
    _bidonVolumeMl.dispose();
    _maxRefillCount.dispose();
    _maxBottleAgeDays.dispose();
    _lowBottleThreshold.dispose();
    _lowBidonThreshold.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
          _isEditing ? l10n.t('productsBtnEdit') : l10n.t('productsBtnCreate')),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RequiredTextField(
                    controller: _sku, label: l10n.t('productsLabelSku')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RequiredTextField(
                        controller: _nameEn,
                        label: l10n.t('productsLabelNameEn'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RequiredTextField(
                        controller: _nameFr,
                        label: l10n.t('productsLabelNameFr'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RequiredTextField(
                        controller: _nameAr,
                        label: l10n.t('productsLabelNameAr'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RequiredTextField(
                        controller: _nameIt,
                        label: l10n.t('productsLabelNameIt'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('productsLabelImage'),
                    hintText: l10n.t('productsLabelImageHint'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PositiveIntField(
                      controller: _bottleVolumeMl,
                      label: l10n.t('productsLabelBottleMl'),
                    ),
                    _PositiveIntField(
                      controller: _bidonVolumeMl,
                      label: l10n.t('productsLabelBidonMl'),
                    ),
                    _PositiveIntField(
                      controller: _maxRefillCount,
                      label: l10n.t('productsLabelMaxRefills'),
                    ),
                    _PositiveIntField(
                      controller: _maxBottleAgeDays,
                      label: l10n.t('productsLabelMaxAgeDays'),
                    ),
                    _PositiveIntField(
                      controller: _lowBottleThreshold,
                      label: l10n.t('productsLabelLowBottles'),
                    ),
                    _PositiveIntField(
                      controller: _lowBidonThreshold,
                      label: l10n.t('productsLabelLowBidons'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.t('btnCancel')),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_outlined),
          label: Text(_isEditing ? l10n.t('btnSave') : l10n.t('btnCreate')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(repositoryProvider);
      final product = widget.product;
      if (product == null) {
        await repository.createProduct(
          sku: _sku.text.trim(),
          nameEn: _nameEn.text.trim(),
          nameFr: _nameFr.text.trim(),
          nameAr: _nameAr.text.trim(),
          nameIt: _nameIt.text.trim(),
          bottleVolumeMl: int.parse(_bottleVolumeMl.text),
          bidonVolumeMl: int.parse(_bidonVolumeMl.text),
          maxRefillCount: int.parse(_maxRefillCount.text),
          maxBottleAgeDays: int.parse(_maxBottleAgeDays.text),
          lowBottleThreshold: int.parse(_lowBottleThreshold.text),
          lowBidonThreshold: int.parse(_lowBidonThreshold.text),
          imageUrl: _imageUrl.text.trim(),
        );
      } else {
        await repository.updateProduct(
          productId: product.id,
          sku: _sku.text.trim(),
          nameEn: _nameEn.text.trim(),
          nameFr: _nameFr.text.trim(),
          nameAr: _nameAr.text.trim(),
          nameIt: _nameIt.text.trim(),
          bottleVolumeMl: int.parse(_bottleVolumeMl.text),
          bidonVolumeMl: int.parse(_bidonVolumeMl.text),
          maxRefillCount: int.parse(_maxRefillCount.text),
          maxBottleAgeDays: int.parse(_maxBottleAgeDays.text),
          lowBottleThreshold: int.parse(_lowBottleThreshold.text),
          lowBidonThreshold: int.parse(_lowBidonThreshold.text),
          imageUrl: _imageUrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.t('requiredField');
        }
        return null;
      },
    );
  }
}

class _PositiveIntField extends StatelessWidget {
  const _PositiveIntField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 192,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          if (parsed == null || parsed <= 0) return l10n.t('enterNumberError');
          return null;
        },
      ),
    );
  }
}
