import 'package:flutter/material.dart';
import 'product_image.dart';

class HoverImageTooltip extends StatelessWidget {
  const HoverImageTooltip({
    super.key,
    required this.child,
    this.imageUrl,
    this.imageSize = 250.0,
  });

  final Widget child;
  final String? imageUrl;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return child;
    }

    return Tooltip(
      preferBelow: false,
      verticalOffset: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 5,
          )
        ],
      ),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      richMessage: WidgetSpan(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: imageSize,
            height: imageSize,
            child: ProductImage(
              imagePath: imageUrl!,
              fit: BoxFit.cover,
              iconSize: 48.0,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
