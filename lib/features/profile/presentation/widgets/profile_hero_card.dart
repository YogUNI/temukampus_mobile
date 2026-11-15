import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../auth/data/models/user_model.dart';

/// Kartu identitas utama di halaman Profil.
///
/// Satu kartu bergradasi cobalt dengan motif tiket, avatar bercincin putih,
/// chip prodi/angkatan, dan strip status di bawah garis perforasi. Semua nilai
/// berasal dari API (`/profile`) — tidak ada angka contoh seperti "12 Poin".
class ProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAvatarTap;

  const ProfileHeroCard({
    super.key,
    required this.user,
    required this.onAvatarTap,
  });

  String get _initials {
    final parts = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'TK';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isUmb = user.accountType == 'umb';

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.borderXl,
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.borderXl,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cobalt, AppColors.cobaltDark],
            ),
          ),
          child: Stack(
            children: [
              // Motif tiket samar di pojok kanan.
              Positioned(
                top: -18,
                right: -34,
                child: Opacity(
                  opacity: 0.16,
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(
                          user: user,
                          initials: _initials,
                          onTap: onAvatarTap,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.82),
                                      ),
                                    ),
                                  ),
                                  if (user.emailVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.mint,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Chip prodi + angkatan (data nyata dari NIM).
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isUmb && user.studyProgram != null)
                          _HeroChip(
                            icon: Icons.school_rounded,
                            label: user.studyProgram!.name,
                          ),
                        if (isUmb && user.cohortYear != null)
                          _HeroChip(
                            icon: Icons.calendar_month_rounded,
                            label: "Angkatan ${user.cohortYear}",
                          ),
                        if (!isUmb && user.institutionName != null)
                          _HeroChip(
                            icon: Icons.apartment_rounded,
                            label: user.institutionName!,
                          ),
                        if (user.isOrganizer)
                          const _HeroChip(
                            icon: Icons.verified_user_rounded,
                            label: 'Panitia',
                            accent: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Garis perforasi: memisahkan identitas dari status.
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: CustomPaint(
                            painter: _DashedLinePainter(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: _HeroStat(
                            label: 'NIM',
                            value: user.nim ?? '—',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 26,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        Expanded(
                          child: _HeroStat(
                            label: 'Status Akun',
                            value: user.status == 'active' ? 'Aktif' : 'Ditangguhkan',
                            valueColor: user.status == 'active'
                                ? AppColors.mint
                                : AppColors.signal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;
  final String initials;
  final VoidCallback onTap;

  const _Avatar({
    required this.user,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? AppNetworkOrAssetImage(
                          imagePath: user.avatarUrl!,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorWidget: _InitialsAvatar(initials: initials),
                        )
                      : _InitialsAvatar(initials: initials),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.ink,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cobaltLight,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.cobalt,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const _HeroChip({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.signal
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.borderPill,
        border: Border.all(
          color: accent
              ? AppColors.ink.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent ? AppColors.ink : Colors.white),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent ? AppColors.ink : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HeroStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.micro.copyWith(
            fontSize: 8.5,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.62),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;

    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
