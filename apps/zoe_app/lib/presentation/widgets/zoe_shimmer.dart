/// Widget de loading com shimmer effect luxury.
///
/// Referências:
/// - ARCHITECTURE.md §Design System: shimmer para skeleton screens
/// - prompt.md §3.1: shimmer package
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/zoe_colors.dart';

class ZoeShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double? itemWidth;

  const ZoeShimmerLoading({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 200,
    this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ZoeColors.surface,
      highlightColor: ZoeColors.background,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Shimmer para lista vertical (single column)
class ZoeShimmerList extends StatelessWidget {
  final int itemCount;

  const ZoeShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ZoeColors.surface,
      highlightColor: ZoeColors.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
