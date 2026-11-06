import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../core/utils/haptics.dart';

/// Kerangka utama dengan dock navigasi kapsul yang mengambang di atas konten.
///
/// Bukan `BottomNavigationBar` bawaan Material: dock mengambang memberi ruang
/// napas pada konten dan menempatkan keempat tujuan di dalam thumb zone.
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
    AppHaptics.selection();
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
        bottomNavigationBar: FloatingNavDock(
          selectedIndex: selectedIndex,
          onIndexChanged: (index) => _onItemTapped(index, context),
        ),
      ),
    );
  }
}

/// Dock kapsul mengambang. Publik agar geometrinya bisa diverifikasi tes.
class FloatingNavDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const FloatingNavDock({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  static const List<({String label, IconData icon, IconData activeIcon})> _items = [
    (label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    (label: 'Jelajah', icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded),
    (
      label: 'Tiket Saya',
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded
    ),
    (label: 'Profil', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        key: const ValueKey('nav_dock'),
        height: 64, // tinggi dock: 64 (8-pt grid) + inset bawah 12
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderPill,
          border: Border.all(color: AppColors.ink100),
          boxShadow: AppShadows.dockBar,
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _DockItem(
                  label: _items[i].label,
                  icon: _items[i].icon,
                  activeIcon: _items[i].activeIcon,
                  isSelected: selectedIndex == i,
                  onTap: () => onIndexChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.cobalt : AppColors.ink400;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        key: ValueKey('nav_dock_item_$label'),
        onTap: onTap,
        borderRadius: AppRadii.borderPill,
        splashColor: AppColors.cobalt.withValues(alpha: 0.05),
        child: Center(
          child: AnimatedContainer(
            duration: AppDurations.base,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.cobaltLight : Colors.transparent,
              borderRadius: AppRadii.borderPill,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    letterSpacing: 0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
