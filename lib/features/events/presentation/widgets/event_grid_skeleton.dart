import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import 'event_grid_metrics.dart';

/// Skeleton grid 2-kolom yang meniru bentuk [EventGridCard].
///
/// Memakai geometri yang sama dengan grid asli supaya tidak ada "lompatan
/// layout" saat data selesai dimuat.
class EventGridSkeleton extends StatelessWidget {
  final int itemCount;

  const EventGridSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          gridDelegate: EventGridMetrics.delegate(constraints.maxWidth),
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: AppColors.ink100,
              highlightColor: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.borderMd,
                  border: Border.all(color: AppColors.ink100),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(color: AppColors.ink200),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: AppSpacing.cardCompact,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bar(width: 60, height: 8),
                            const SizedBox(height: AppSpacing.sm),
                            _bar(height: 12),
                            const SizedBox(height: AppSpacing.xs),
                            _bar(width: 90, height: 12),
                            const Spacer(),
                            _bar(width: 70, height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bar({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderXs,
      ),
    );
  }
}
