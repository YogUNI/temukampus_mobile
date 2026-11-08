import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
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
///
/// Geometri (semua bilangan 8-pt grid, diverifikasi `event_grid_layout_test`):
/// - tinggi 68, radius 30, margin samping 20, inset bawah 12
/// - item lebar sama (Expanded), target sentuh >= 44x44
/// - item aktif = kapsul cobalt dengan ikon putih + label tebal (gaya tab bar
///   iOS 26: kapsul di sekitar ikon, bukan pil besar di belakang seluruh item)
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

  /// Tinggi kapsul dock.
  static const double dockHeight = 68;

  /// Radius sudut kapsul.
  static const double dockRadius = 30;

  /// Margin kiri/kanan dock terhadap tepi layar.
  static const double dockMargin = AppSpacing.gutter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        dockMargin,
        0,
        dockMargin,
        AppSpacing.md,
      ),
      child: Container(
        key: const ValueKey('nav_dock'),
        height: dockHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(dockRadius),
          border: Border.all(color: AppColors.ink100, width: 1.2),
          boxShadow: [
            // Dua lapis: bayangan jauh yang lembut + bayangan dekat yang tegas,
            // supaya dock benar-benar "mengambang" di atas konten.
            const BoxShadow(
              color: Color(0x2412162B),
              offset: Offset(0, 12),
              blurRadius: 32,
            ),
            const BoxShadow(
              color: Color(0x1212162B),
              offset: Offset(0, 3),
              blurRadius: 9,
            ),
          ],
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

  /// Kapsul ikon aktif: 46x32 (ikon 20 di dalamnya).
  static const double activeCapsuleWidth = 46;
  static const double activeCapsuleHeight = 32;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        key: ValueKey('nav_dock_item_$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.cobalt.withValues(alpha: 0.05),
        highlightColor: AppColors.cobalt.withValues(alpha: 0.03),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kapsul ikon: tumbuh + terisi cobalt saat aktif (iOS 26 style).
              AnimatedContainer(
                duration: AppDurations.base,
                curve: Curves.easeOutCubic,
                width: isSelected ? activeCapsuleWidth : 38,
                height: isSelected ? activeCapsuleHeight : 30,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cobalt : Colors.transparent,
                  borderRadius: BorderRadius.circular(activeCapsuleHeight / 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.cobalt.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 20 : 23,
                      color: isSelected ? Colors.white : AppColors.ink400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: AppTypography.micro.copyWith(
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppColors.cobalt : AppColors.ink400,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}