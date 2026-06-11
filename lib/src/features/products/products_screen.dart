import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/app_enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shared/async_value_view.dart';
import '../shared/page_scaffold.dart';

/// Product create/edit/delete is restricted server-side to Ivra-level roles
/// (`app_admin`/`app_manager`, see the `products_write_ivra` RLS policy).
/// Hotel managers and staff would only hit a permission error, so hide the
/// management controls from them entirely.
bool canManageProducts(UserProfile? user) {
  if (user == null) return false;
  return user.role == UserRole.appAdmin || user.role == UserRole.appManager;
}

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  static const route = '/products';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canManage =
        canManageProducts(ref.watch(currentUserProvider).valueOrNull);
    return PageScaffold(
      title: l10n.t('productsCatalogTitle'),
      onRefresh: () async {
        ref.invalidate(productsProvider);
        await ref.read(productsProvider.future);
      },
      actions: [
        if (canManage)
          IconButton(
            tooltip: l10n.t('productsBtnCreate'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showProductDialog(context, ref),
          ),
      ],
      child: AsyncValueView(
        value: ref.watch(productsProvider),
        onRetry: () => ref.invalidate(productsProvider),
        builder: (products) => _ProductsTable(products: products),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    WidgetRef ref, {
    Product? product,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
    final canManage =
        canManageProducts(ref.watch(currentUserProvider).valueOrNull);

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
        final contentWidth = constraints.maxWidth.clamp(0, 1280).toDouble();
        final columns = contentWidth >= 1100
            ? 3
            : contentWidth >= 720
                ? 2
                : 1;
        final spacing = contentWidth < 420 ? 12.0 : 20.0;
        final cardWidth = (contentWidth - (spacing * (columns - 1))) / columns;

        return Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: contentWidth,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final product in products)
                  SizedBox(
                    width: cardWidth,
                    child: _PremiumProductCard(
                      product: product,
                      language: language,
                      canManage: canManage,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumProductCard extends ConsumerStatefulWidget {
  const _PremiumProductCard({
    required this.product,
    required this.language,
    required this.canManage,
  });

  final Product product;
  final String language;
  final bool canManage;

  @override
  ConsumerState<_PremiumProductCard> createState() =>
      _PremiumProductCardState();
}

class _PremiumProductCardState extends ConsumerState<_PremiumProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.95),
                theme.colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow
                    .withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.primary
                  .withValues(alpha: _isHovered ? 0.4 : 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image Header
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.product.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                          child: Icon(
                            Icons.spa_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // SKU Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          widget.product.sku,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Title over image
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        widget.product.label(widget.language),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          shadows: [
                            const Shadow(
                              color: Colors.black87,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RuleRow(
                        Icons.pin_drop_outlined,
                        l10n.t('productsLabelBottleVolume'),
                        '${widget.product.bottleVolumeMl} ml'),
                    _RuleRow(
                        Icons.propane_tank_outlined,
                        l10n.t('productsLabelBidonVolume'),
                        '${widget.product.bidonVolumeMl} ml'),
                    _RuleRow(
                        Icons.loop_outlined,
                        l10n.t('productsLabelMaxRefill'),
                        '${widget.product.maxRefillCount} ${l10n.t('refills')}'),
                    _RuleRow(
                        Icons.calendar_today_outlined,
                        l10n.t('productsLabelMaxAge'),
                        '${widget.product.maxBottleAgeDays} ${l10n.t('days')}'),
                    _RuleRow(
                      Icons.warning_amber_outlined,
                      l10n.t('productsLabelLowStock'),
                      '${widget.product.lowBottleThreshold} ${l10n.t('bottles').toLowerCase()} / ${widget.product.lowBidonThreshold} ${l10n.t('bidons').toLowerCase()}',
                    ),
                    if (widget.canManage) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              l10n.t('productsBtnEdit'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) =>
                                  _ProductDialog(product: widget.product),
                            ).then((_) {
                              ref.invalidate(productsProvider);
                              ref.invalidate(roomProductsProvider);
                              ref.invalidate(inventoryProvider);
                              ref.invalidate(suggestedOrdersProvider);
                              ref.invalidate(dashboardProvider);
                            }),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: l10n.t('delete'),
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.error),
                            onPressed: () => _confirmDelete(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text('${l10n.t('productsLabelNameEn')}: ${widget.product.nameEn}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('btnCancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(repositoryProvider).deleteProduct(widget.product.id);
        ref.invalidate(productsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
  XFile? _selectedImage;
  String? _currentImageUrl;
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
    _currentImageUrl = product?.imageUrl;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing
                  ? l10n.t('productsBtnEdit')
                  : l10n.t('productsBtnCreate'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedImage != null
                                  ? 'Selected: ${_selectedImage!.name}'
                                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                      ? 'Image is set (tap to change)'
                                      : 'No image selected'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _selectedImage != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image_search),
                            label: Text(l10n.t('productsLabelImage')),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _selectedImage = image;
                                });
                              }
                            },
                          ),
                        ],
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.t('btnCancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: Icon(
                      _isEditing ? Icons.save_outlined : Icons.add_outlined),
                  label: Text(
                      _isEditing ? l10n.t('btnSave') : l10n.t('btnCreate')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(repositoryProvider);
      final product = widget.product;
      String? finalImageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.name.contains('.') ? _selectedImage!.name.split('.').last : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        try {
          await Supabase.instance.client.storage
              .from('products')
              .uploadBinary(fileName, bytes,
                  fileOptions: const FileOptions(upsert: true));
        } catch (e) {
          // If bucket doesn't exist or other error, let's try to create it just in case
          try {
            await Supabase.instance.client.storage.createBucket('products', const BucketOptions(public: true));
            await Supabase.instance.client.storage
                .from('products')
                .uploadBinary(fileName, bytes,
                    fileOptions: const FileOptions(upsert: true));
          } catch (_) {}
        }
        
        finalImageUrl = Supabase.instance.client.storage
            .from('products')
            .getPublicUrl(fileName);
      }

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
          imageUrl: finalImageUrl,
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
          imageUrl: finalImageUrl,
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
