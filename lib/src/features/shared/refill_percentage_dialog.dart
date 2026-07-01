import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models.dart';
import 'animated_bottle_refill_indicator.dart';

class RefillResult {
  const RefillResult({
    required this.refillPercentage,
    required this.notes,
  });

  final int refillPercentage;
  final String notes;
}

class RefillPercentageDialog extends StatefulWidget {
  const RefillPercentageDialog({
    super.key,
    required this.item,
  });

  final RoomProduct item;

  static Future<RefillResult?> show(
    BuildContext context,
    RoomProduct item,
  ) async {
    return showDialog<RefillResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => RefillPercentageDialog(item: item),
    );
  }

  @override
  State<RefillPercentageDialog> createState() => _RefillPercentageDialogState();
}

class _RefillPercentageDialogState extends State<RefillPercentageDialog> {
  double _refillPercentage = 0.1; // Default to 10% (0.1)
  bool _isSliderInteracting = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final int refillPercentInt = (_refillPercentage * 100).round();
    final int preExistingPercentInt = 100 - refillPercentInt;

    // Design-system-aligned luxurious colors
    final Color baseColor = theme.colorScheme.primary;
    final Color accentColor = theme.brightness == Brightness.dark
        ? Colors.cyanAccent.shade400
        : Colors.teal.shade400;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: colorScheme.surface.withValues(alpha: 0.9),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Text(
                        l10n.t('dialogRefillTitle'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.product.label(Localizations.localeOf(context).languageCode),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Animated Bottle representation with 4-language localized labels inside
                      AnimatedBottleRefillIndicator(
                        refillPercentage: _refillPercentage,
                        bottleVolumeMl: widget.item.product.bottleVolumeMl,
                        isInteracting: _isSliderInteracting,
                        baseColor: baseColor,
                        accentColor: accentColor,
                        width: 140,
                        height: 200,
                        existingLabel: l10n.t('dialogRefillPreExisting').replaceAll(':', '').replaceAll('：', '').trim(),
                        toAddLabel: l10n.t('dialogRefillAdded').replaceAll(':', '').replaceAll('：', '').trim(),
                      ),
                      const SizedBox(height: 24),

                      // Legends displaying Already Full vs To Add
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          // Already Full
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.t('dialogRefillPreExisting')} $preExistingPercentInt%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          // To Add
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.t('dialogRefillAdded')} $refillPercentInt%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Slider Label & Slider
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.t('dialogRefillSliderLabel'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accentColor,
                          inactiveTrackColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          thumbColor: accentColor,
                          overlayColor: accentColor.withValues(alpha: 0.15),
                          valueIndicatorColor: accentColor,
                          valueIndicatorTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        child: Slider(
                          value: _refillPercentage,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '$refillPercentInt%',
                          onChangeStart: (_) {
                            setState(() {
                              _isSliderInteracting = true;
                            });
                          },
                          onChangeEnd: (_) {
                            setState(() {
                              _isSliderInteracting = false;
                            });
                          },
                          onChanged: (val) {
                            setState(() {
                              _refillPercentage = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notes text field
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: l10n.t('dialogRefillNotes'),
                          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          hintText: 'e.g. standard refill...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentColor, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        maxLength: 120,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.5),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                l10n.t('btnCancel'),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(
                                  RefillResult(
                                    refillPercentage: refillPercentInt,
                                    notes: _notesController.text.trim(),
                                  ),
                                );
                              },
                              child: Text(
                                l10n.t('dialogRefillConfirm'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
