import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows [child] as a centered, dialog-style popup instead of a
/// bottom-anchored modal sheet.
///
/// The room and product forms were previously shown with
/// [showModalBottomSheet], which anchors them to the bottom of the screen and
/// makes them appear shifted down rather than centered. This helper renders the
/// exact same form widgets inside a centered, width-constrained, scrollable
/// container so they sit in the middle of the screen on every platform while
/// still avoiding the on-screen keyboard via [MediaQuery.viewInsetsOf].
Future<T?> showCenteredFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 560,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) {
      return _CenteredFormSheetDialog(
        builder: builder,
        maxWidth: maxWidth,
      );
    },
  );
}

class _CenteredFormSheetDialog extends StatefulWidget {
  const _CenteredFormSheetDialog({
    required this.builder,
    required this.maxWidth,
  });

  final WidgetBuilder builder;
  final double maxWidth;

  @override
  State<_CenteredFormSheetDialog> createState() => _CenteredFormSheetDialogState();
}

class _CenteredFormSheetDialogState extends State<_CenteredFormSheetDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Keep the popup within the visible area, leaving room for the keyboard.
    final maxHeight = media.size.height - media.padding.vertical - 48 - bottomInset;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth,
              maxHeight: maxHeight > 0 ? maxHeight : media.size.height,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: widget.builder(context),
                    ),
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
