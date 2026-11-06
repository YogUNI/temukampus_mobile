import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.explore)) return 1;
    if (location.startsWith(AppRoutes.myTickets)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // Default Beranda
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.explore);
        break;
      case 2:
        context.go(AppRoutes.myTickets);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedIndex != 0) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.ink100, width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  isSelected: selectedIndex == 0,
                  label: 'Beranda',
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  isSelected: selectedIndex == 1,
                  label: 'Jelajah',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  isSelected: selectedIndex == 2,
                  label: 'Tiket Saya',
                  icon: Icons.confirmation_number_outlined,
                  activeIcon: Icons.confirmation_number_rounded,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  isSelected: selectedIndex == 3,
                  label: 'Profil',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required bool isSelected,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.cobalt : AppColors.ink400,
                size: 24,
              ),
              if (isSelected)
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.signal, // Titik Sinyal TemuKampus
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.badge.copyWith(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.cobalt : AppColors.ink500,
            ),
          ),
        ],
      ),
    );
  }
}

