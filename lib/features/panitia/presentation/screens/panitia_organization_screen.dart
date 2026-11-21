import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/datasources/panitia_remote_datasource.dart';
import '../../data/models/panitia_models.dart';
import '../controllers/panitia_controller.dart';

/// Layar Kelola Profil Organisasi Panitia (F-09, FR-ORG-009).
/// Owner dapat memperbarui nama, deskripsi, email, akun Instagram, dan logo ormawa.
class PanitiaOrganizationScreen extends ConsumerStatefulWidget {
  const PanitiaOrganizationScreen({super.key});

  @override
  ConsumerState<PanitiaOrganizationScreen> createState() =>
      _PanitiaOrganizationScreenState();
}

class _PanitiaOrganizationScreenState
    extends ConsumerState<PanitiaOrganizationScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _logoFile;
  bool _isSaving = false;
  Map<String, String> _fieldErrors = {};
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _populate(PanitiaOrganizationModel org) {
    if (_initialized) return;
    _nameController.text = org.name;
    _descriptionController.text = org.description ?? '';
    _emailController.text = org.email ?? '';
    _instagramController.text = org.instagram ?? '';
    _initialized = true;
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.ink,
      ),
    );
  }

  Future<void> _pickLogo() async {
    AppHaptics.selection();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (picked != null) {
      setState(() {
        _logoFile = File(picked.path);
        _fieldErrors.remove('logo');
      });
    }
  }

  Future<void> _save() async {
    AppHaptics.selection();
    setState(() {
      _isSaving = true;
      _fieldErrors = {};
    });

    try {
      final map = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'instagram': _instagramController.text.trim(),
        '_method': 'PUT',
      };

      if (_logoFile != null) {
        map['logo'] = await MultipartFile.fromFile(
          _logoFile!.path,
          filename: _logoFile!.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = FormData.fromMap(map);
      await ref
          .read(panitiaRemoteDataSourceProvider)
          .updateOrganization(formData);

      if (!mounted) return;

      AppHaptics.success();
      _snack('Profil organisasi berhasil diperbarui.');
      ref.invalidate(panitiaOrganizationProvider);
      ref.invalidate(panitiaEventsProvider);
    } on ValidationException catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      final map = <String, String>{};
      e.fieldErrors.forEach((key, list) {
        if (list.isNotEmpty) map[key] = list.first;
      });
      setState(() => _fieldErrors = map);
      _snack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(panitiaOrganizationProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Profil Organisasi', style: AppTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined, color: AppColors.ink),
            tooltip: 'Anggota Tim',
            onPressed: () {
              AppHaptics.selection();
              context.push(AppRoutes.panitiaMembers);
            },
          ),
        ],
      ),
      body: orgAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cobalt),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.corporate_fare_rounded,
                    size: 48, color: AppColors.ink400),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Gagal memuat profil organisasi.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => ref.invalidate(panitiaOrganizationProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (org) {
          _populate(org);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              // Logo & Status Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.borderLg,
                  boxShadow: AppShadows.softCard,
                  border: Border.all(color: AppColors.ink200),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: org.isOwner ? _pickLogo : null,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cobaltLight,
                              border: Border.all(
                                color: _fieldErrors.containsKey('logo')
                                    ? AppColors.danger
                                    : AppColors.cobalt,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _logoFile != null
                                  ? Image.file(_logoFile!, fit: BoxFit.cover)
                                  : (org.logoUrl != null && org.logoUrl!.isNotEmpty)
                                      ? Image.network(org.logoUrl!, fit: BoxFit.cover)
                                      : Center(
                                          child: Text(
                                            org.name.isNotEmpty
                                                ? org.name[0].toUpperCase()
                                                : 'O',
                                            style: AppTypography.titleMedium.copyWith(
                                              color: AppColors.cobalt,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        if (org.isOwner)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickLogo,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobalt,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      org.name,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: AppRadii.borderPill,
                      ),
                      child: Text(
                        'Organisasi Aktif',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.mintText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (org.faculty != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${org.faculty}${org.studyProgram != null ? " · ${org.studyProgram}" : ""}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Quick stats & link to members
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_rounded,
                      value: '${org.eventsCount}',
                      label: 'Total Acara',
                      color: AppColors.cobalt,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AppHaptics.selection();
                        context.push(AppRoutes.panitiaMembers);
                      },
                      child: _StatCard(
                        icon: Icons.group_outlined,
                        value: '${org.membersCount}',
                        label: 'Anggota Panitia',
                        color: AppColors.signal,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.ink400),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              Text('Informasi Ormawa',
                  style: AppTypography.label.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),

              _buildField(
                controller: _nameController,
                label: 'Nama Organisasi *',
                hint: 'Contoh: BEM FASILKOM UMB',
                fieldKey: 'name',
                enabled: org.isOwner,
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildField(
                controller: _descriptionController,
                label: 'Deskripsi Profil',
                hint: 'Ceritakan visi dan fokus kegiatan organisasi...',
                fieldKey: 'description',
                maxLines: 4,
                enabled: org.isOwner,
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildField(
                controller: _emailController,
                label: 'Email Kontak Resmi',
                hint: 'kontak@bem-fasilkom.org',
                fieldKey: 'contact_email',
                keyboardType: TextInputType.emailAddress,
                enabled: org.isOwner,
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildField(
                controller: _instagramController,
                label: 'Akun Instagram (Tanpa @)',
                hint: 'bemfasilkom_umb',
                fieldKey: 'instagram',
                prefixText: '@ ',
                enabled: org.isOwner,
              ),

              const SizedBox(height: AppSpacing.xl),

              if (org.isOwner)
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cobalt,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Perubahan Profil'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String fieldKey,
    int maxLines = 1,
    String? prefixText,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    final hasErr = _fieldErrors.containsKey(fieldKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium,
          onChanged: (_) {
            if (_fieldErrors.containsKey(fieldKey)) {
              setState(() => _fieldErrors.remove(fieldKey));
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.cobalt),
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.ink400),
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.ink100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: BorderSide(color: hasErr ? AppColors.danger : AppColors.ink300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: BorderSide(color: hasErr ? AppColors.danger : AppColors.ink300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: const BorderSide(color: AppColors.cobalt, width: 1.8),
            ),
          ),
        ),
        if (hasErr) ...[
          const SizedBox(height: 4),
          Text(_fieldErrors[fieldKey]!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Widget? trailing;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink200, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
