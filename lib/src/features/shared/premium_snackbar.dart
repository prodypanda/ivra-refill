import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumSnackbar {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline,
    Color? iconColor,
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final backgroundColor = isError 
        ? colorScheme.errorContainer.withValues(alpha: 0.85)
        : colorScheme.surface.withValues(alpha: 0.85);
        
    final textColor = isError 
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;
        
    final iconColorToUse = iconColor ?? (isError ? colorScheme.error : colorScheme.primary);

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColorToUse),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
