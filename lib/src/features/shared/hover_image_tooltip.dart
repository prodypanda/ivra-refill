import 'package:flutter/material.dart';

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
    if (imageUrl == null || imageUrl!.isEmpty || !imageUrl!.startsWith('http')) {
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
            color: Colors.black.withOpacity(0.2),
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
          child: Image.network(
            imageUrl!,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: imageSize,
                height: imageSize,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => SizedBox(
              width: imageSize,
              height: imageSize,
              child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
