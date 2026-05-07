/// Widget Shimmer Loading — efek loading skeleton seperti Tokopedia/Shopee.
/// Reusable di seluruh screen yang butuh loading state.
library;

import 'package:flutter/material.dart';

/// Widget shimmer yang membuat efek berkilau saat loading.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.withValues(alpha: 0.3),
                Colors.grey.withValues(alpha: 0.1),
                Colors.grey.withValues(alpha: 0.3),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              // Clamp agar tidak error saat value mendekati batas
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton placeholder box — balok abu-abu dengan rounded corner.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final is_dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: is_dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// =========================================================
// PRESET SKELETON — siap pakai untuk berbagai screen
// =========================================================

/// Skeleton untuk satu card pocket di Home screen.
class PocketCardSkeleton extends StatelessWidget {
  const PocketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ikon placeholder
              const SkeletonBox(width: 48, height: 48, radius: 14),
              const SizedBox(width: 14),
              // Info placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 16),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 60, height: 12),
                  ],
                ),
              ),
              // Saldo placeholder
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 80, height: 16),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 30, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton untuk satu tile transaksi.
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ikon placeholder
              const SkeletonBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: 12),
              // Info placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 100, height: 14),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 10),
                  ],
                ),
              ),
              // Nominal placeholder
              SkeletonBox(width: 70, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// List skeleton — menampilkan N skeleton items.
class SkeletonList extends StatelessWidget {
  final int item_count;
  final Widget Function(BuildContext, int) item_builder;

  const SkeletonList({
    super.key,
    this.item_count = 5,
    required this.item_builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: item_count,
      itemBuilder: item_builder,
    );
  }
}
