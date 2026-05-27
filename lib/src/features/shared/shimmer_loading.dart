import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Shimmer.fromColors(
      baseColor: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
      highlightColor: isLight ? Colors.grey.shade50 : Colors.grey.shade700,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CardShimmer extends StatelessWidget {
  const CardShimmer({this.isCompact = false, super.key});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight ? Colors.white.withValues(alpha: 0.7) : null,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerLoading(width: 120, height: 16),
                        SizedBox(height: 8),
                        ShimmerLoading(width: 80, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 24),
                const ShimmerLoading(width: double.infinity, height: 12),
                const SizedBox(height: 8),
                const ShimmerLoading(width: double.infinity, height: 12),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 150, height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of pulsing shimmer metric cards (for dashboard loading state).
class MetricCardShimmer extends StatelessWidget {
  const MetricCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const ShimmerLoading(width: 56, height: 56, borderRadius: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerLoading(width: 60, height: 28, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerLoading(width: 100, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
