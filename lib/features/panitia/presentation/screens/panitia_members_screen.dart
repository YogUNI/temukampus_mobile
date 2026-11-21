import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/datasources/panitia_remote_datasource.dart';
import '../../data/models/panitia_models.dart';
import '../controllers/panitia_controller.dart';

/// Layar Daftar & Kelola Anggota Panitia (FR-ORG-008, BR-18).
/// Owner dapat mengundang staf baru via email dan mencabut akses staf.
class PanitiaMembersScreen extends ConsumerStatefulWidget {
  const PanitiaMembersScreen({super.key});

  @override
  ConsumerState<PanitiaMembersScreen> createState() => _PanitiaMembersScreenState();
}

class _PanitiaMembersScreenState extends ConsumerState<PanitiaMembersScreen> {
  int? _busyUserId;

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.ink,
      ),
    );
  }

  Future<void> _showInviteDialog() async {
    AppHaptics.selection();
    final emailController = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
            title: Text('Undang Staf Panitia', style: AppTypography.titleSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan alamat email mahasiswa atau akun yang terdaftar di TemuKampus.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'nama@student.mercubuana.ac.id',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.ink400),
                    errorText: errorText,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: AppRadii.borderMd),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    setDialogState(() => errorText = 'Masukkan format email yang valid.');
                    return;
                  }
                  Navigator.pop(ctx, email);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.cobalt),
                child: const Text('Undang'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _invite(result);
    }
  }

  Future<void> _invite(String email) async {
    try {
      final msg = await ref
          .read(panitiaRemoteDataSourceProvider)
          .inviteMember(email);

      if (!mounted) return;
      AppHaptics.success();
      _snack(msg);
      ref.invalidate(panitiaMembersProvider);
      ref.invalidate(panitiaOrganizationProvider);
    } on ValidationException catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(e.firstErrorFor('email') ?? e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(e.toString(), isError: true);
    }
  }

  Future<void> _remove(PanitiaMemberModel member) async {
    AppHaptics.selection();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: const Text('Hapus staf dari organisasi?'),
        content: Text(
          'Akses panel panitia untuk ${member.name} (${member.email}) akan dicabut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus Akses'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busyUserId = member.userId);
    try {
      final msg = await ref
          .read(panitiaRemoteDataSourceProvider)
          .removeMember(member.userId);

      if (!mounted) return;
      AppHaptics.success();
      _snack(msg);
      ref.invalidate(panitiaMembersProvider);
      ref.invalidate(panitiaOrganizationProvider);
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(panitiaMembersProvider);
    final orgAsync = ref.watch(panitiaOrganizationProvider);
    final isOwner = orgAsync.valueOrNull?.isOwner ?? false;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Anggota Tim Panitia', style: AppTypography.titleMedium),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: AppColors.cobalt),
              tooltip: 'Undang Staf Baru',
              onPressed: _showInviteDialog,
            ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: _showInviteDialog,
              backgroundColor: AppColors.cobalt,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Undang Staf'),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.cobalt,
        onRefresh: () async {
          ref.invalidate(panitiaMembersProvider);
        },
        child: membersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cobalt),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off_rounded,
                      size: 48, color: AppColors.ink400),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Gagal memuat daftar anggota.',
                      style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(panitiaMembersProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return Center(
                child: Text(
                  'Belum ada anggota terdaftar.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl + 40,
              ),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final m = members[index];
                final isBusy = _busyUserId == m.userId;

                DateTime? joinedDate;
                if (m.joinedAt != null) {
                  joinedDate = DateTime.tryParse(m.joinedAt!);
                }
                final joinedStr =
                    joinedDate != null ? AppFormatters.eventDate(joinedDate) : null;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.borderMd,
                    boxShadow: AppShadows.liftedCard,
                    border: Border.all(color: AppColors.ink200, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: m.isOwner ? AppColors.cobaltLight : AppColors.ink100,
                        ),
                        child: ClipOval(
                          child: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                              ? Image.network(m.avatarUrl!, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: m.isOwner ? AppColors.cobalt : AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    m.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: m.isOwner
                                        ? AppColors.cobaltLight
                                        : AppColors.ink100,
                                    borderRadius: AppRadii.borderPill,
                                  ),
                                  child: Text(
                                    m.roleLabel,
                                    style: AppTypography.micro.copyWith(
                                      color: m.isOwner
                                          ? AppColors.cobalt
                                          : AppColors.ink500,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                            ),
                            if (joinedStr != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Bergabung sejak $joinedStr',
                                style: AppTypography.micro.copyWith(color: AppColors.ink400),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isOwner && !m.isOwner)
                        isBusy
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.danger),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded,
                                    color: AppColors.danger, size: 20),
                                tooltip: 'Hapus Staf',
                                onPressed: () => _remove(m),
                              ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
