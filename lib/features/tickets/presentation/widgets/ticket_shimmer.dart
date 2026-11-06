import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import 'ticket_list_card.dart';

/// Skeleton berbentuk tiket untuk daftar "Tiket Saya".
class TicketShimmer extends StatelessWidget {
  final int itemCount;

  const TicketShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Shimmer.fromColors(
            baseColor: AppColors.ink100,
            highlightColor: AppColors.surface,
            child: TicketContainer(
              punchRadius: 11,
              punchPositionPercent: TicketListCard.punchPositionPercent,
              borderRadius: 18,
              borderColor: AppColors.ink100,
              borderWidth: 1.2,
              hasShadow: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(TicketListCard.mainPadding),
                    child: SizedBox(
                      height: TicketListCard.mainBlockHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.ink200,
                              borderRadius: AppRadii.borderSm,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bar(height: 12),
                                const SizedBox(height: AppSpacing.sm),
                                _bar(width: 120, height: 12),
                                const SizedBox(height: AppSpacing.md),
                                _bar(width: 90, height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: DottedTearLine(color: AppColors.ink100),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      height: TicketListCard.stubHeight - AppSpacing.lg,
                      child: Row(
                        children: [
                          _bar(width: 90, height: 12),
                          const Spacer(),
                          _bar(width: 70, height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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