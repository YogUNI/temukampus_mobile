import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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

/// Formulir Wizard 4-langkah untuk Membuat atau Mengubah Acara Panitia:
/// - Langkah 1: Info Utama & Unggah Poster (Rasio 4:5)
/// - Langkah 2: Format, Jadwal & Lokasi Acara
/// - Langkah 3: Sasaran Peserta (Audience), Kuota & Benefit
/// - Langkah 4: Biaya Tiket, Pembayaran Manual Transfer / QRIS & Publikasi
class PanitiaEventWizardScreen extends ConsumerStatefulWidget {
  final int? eventId;

  const PanitiaEventWizardScreen({super.key, this.eventId});

  bool get isEditing => eventId != null;

  @override
  ConsumerState<PanitiaEventWizardScreen> createState() =>
      _PanitiaEventWizardScreenState();
}

class _PanitiaEventWizardScreenState
    extends ConsumerState<PanitiaEventWizardScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = {};

  // Form Controllers
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _onlineUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _quotaController = TextEditingController();
  final _waLinkController = TextEditingController();
  final _skpPointsController = TextEditingController();

  // Selected State
  int? _selectedCategoryId;
  String _format = 'offline'; // offline, online, hybrid
  String _audience = 'umb_only'; // umb_only, public, restricted
  final Set<int> _selectedFacultyIds = {};
  final Set<int> _selectedStudyProgramIds = {};
  int? _cohortMin;
  int? _cohortMax;

  DateTime? _startAt;
  DateTime? _endAt;
  DateTime? _regOpenAt;
  DateTime? _regCloseAt;

  bool _isPaid = false;
  bool _useUniqueCode = true;
  bool _certificateProvided = false;

  File? _posterFile;
  String? _existingPosterUrl;

  File? _qrisFile;
  String? _existingQrisUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingEvent();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _slugController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _locationAddressController.dispose();
    _onlineUrlController.dispose();
    _priceController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _instructionsController.dispose();
    _quotaController.dispose();
    _waLinkController.dispose();
    _skpPointsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingEvent() async {
    setState(() => _isLoadingInitial = true);
    try {
      final detail = await ref
          .read(panitiaRemoteDataSourceProvider)
          .getEventDetail(widget.eventId!);

      if (!mounted) return;

      setState(() {
        _titleController.text = detail.title;
        _slugController.text = detail.slug;
        _selectedCategoryId = detail.categoryId;
        _summaryController.text = detail.summary ?? '';
        _descriptionController.text = detail.description ?? '';
        _format = detail.format;
        _locationNameController.text = detail.locationName ?? '';
        _locationAddressController.text = detail.locationAddress ?? '';
        _onlineUrlController.text = detail.onlineUrl ?? '';

        if (detail.startAt != null) _startAt = DateTime.tryParse(detail.startAt!);
        if (detail.endAt != null) _endAt = DateTime.tryParse(detail.endAt!);
        if (detail.registrationOpenAt != null) {
          _regOpenAt = DateTime.tryParse(detail.registrationOpenAt!);
        }
        if (detail.registrationCloseAt != null) {
          _regCloseAt = DateTime.tryParse(detail.registrationCloseAt!);
        }

        _audience = detail.audience;
        _selectedFacultyIds.addAll(detail.facultyIds);
        _selectedStudyProgramIds.addAll(detail.studyProgramIds);
        _cohortMin = detail.cohortMin;
        _cohortMax = detail.cohortMax;
        if (detail.quota != null) _quotaController.text = '${detail.quota}';
        _waLinkController.text = detail.waGroupLink ?? '';
        if (detail.skpPoints != null) {
          _skpPointsController.text = '${detail.skpPoints}';
        }
        _certificateProvided = detail.certificateProvided;

        _isPaid = detail.isPaid;
        if (detail.price > 0) _priceController.text = '${detail.price}';
        _useUniqueCode = detail.useUniqueCode;
        _bankNameController.text = detail.paymentBankName ?? '';
        _accountNumberController.text = detail.paymentAccountNumber ?? '';
        _accountNameController.text = detail.paymentAccountName ?? '';
        _instructionsController.text = detail.paymentInstructions ?? '';

        _existingPosterUrl = detail.posterUrl;
        _existingQrisUrl = detail.paymentQrisUrl;
      });
    } catch (e) {
      if (mounted) {
        _snack('Gagal memuat data acara: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.ink,
      ),
    );
  }

  Future<void> _pickPoster() async {
    AppHaptics.selection();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 2400,
      imageQuality: 88,
    );

    if (picked != null) {
      setState(() {
        _posterFile = File(picked.path);
        _fieldErrors.remove('poster');
      });
    }
  }

  Future<void> _pickQris() async {
    AppHaptics.selection();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );

    if (picked != null) {
      setState(() {
        _qrisFile = File(picked.path);
        _fieldErrors.remove('payment_qris');
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    AppHaptics.selection();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.cobalt,
            onPrimary: Colors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(hour: initial.hour, minute: initial.minute)
          : const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.cobalt,
            onPrimary: Colors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _validateCurrentStep() {
    setState(() => _fieldErrors = {});
    final errors = <String, String>{};

    if (_currentStep == 0) {
      if (_titleController.text.trim().length < 5) {
        errors['title'] = 'Judul acara minimal 5 karakter.';
      }
      if (_selectedCategoryId == null) {
        errors['category_id'] = 'Pilih salah satu kategori acara.';
      }
      if (!widget.isEditing && _posterFile == null) {
        errors['poster'] = 'Unggah poster acara dengan orientasi tegak (4:5).';
      }
    } else if (_currentStep == 1) {
      if (_format != 'online' && _locationNameController.text.trim().isEmpty) {
        errors['location_name'] = 'Nama lokasi acara tatap muka wajib diisi.';
      }
      if (_format != 'offline' && _onlineUrlController.text.trim().isEmpty) {
        errors['online_url'] = 'Tautan daring (Zoom/GMeet) wajib diisi.';
      }
      if (_startAt == null) {
        errors['start_at'] = 'Pilih tanggal & jam mulai acara.';
      }
      if (_endAt == null) {
        errors['end_at'] = 'Pilih tanggal & jam selesai acara.';
      } else if (_startAt != null && _endAt!.isBefore(_startAt!)) {
        errors['end_at'] = 'Waktu selesai tidak boleh sebelum waktu mulai.';
      }
    } else if (_currentStep == 2) {
      if (_audience == 'restricted') {
        if (_selectedFacultyIds.isEmpty &&
            _selectedStudyProgramIds.isEmpty &&
            _cohortMin == null &&
            _cohortMax == null) {
          errors['audience'] =
              'Pilih minimal satu fakultas, prodi, atau batasan angkatan.';
        }
      }
    } else if (_currentStep == 3) {
      if (_isPaid) {
        final price = int.tryParse(_priceController.text.replaceAll('.', '')) ?? 0;
        if (price < 1000 || price > 10000000) {
          errors['price'] = 'Harga tiket acara berbayar harus Rp 1.000 s.d. Rp 10.000.000.';
        }
        final hasBank = _bankNameController.text.trim().isNotEmpty &&
            _accountNumberController.text.trim().isNotEmpty &&
            _accountNameController.text.trim().isNotEmpty;
        final hasQris = _qrisFile != null || _existingQrisUrl != null;

        if (!hasBank && !hasQris) {
          errors['payment_bank_name'] =
              'Wajib menyertakan minimal rekening bank atau gambar QRIS.';
        }
      }
    }

    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      AppHaptics.error();
      return false;
    }

    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 3) {
      AppHaptics.selection();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      AppHaptics.selection();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submit({required bool publishNow}) async {
    if (!_validateCurrentStep()) return;

    AppHaptics.selection();
    setState(() => _isSubmitting = true);

    try {
      final map = <String, dynamic>{
        'title': _titleController.text.trim(),
        'category_id': _selectedCategoryId,
        'format': _format,
        'audience': _audience,
        'is_paid': _isPaid ? '1' : '0',
        'use_unique_code': _useUniqueCode ? '1' : '0',
        'certificate_provided': _certificateProvided ? '1' : '0',
        'publish_now': publishNow ? '1' : '0',
      };

      if (_slugController.text.trim().isNotEmpty) {
        map['slug'] = _slugController.text.trim().toLowerCase();
      }
      if (_summaryController.text.trim().isNotEmpty) {
        map['summary'] = _summaryController.text.trim();
      }
      if (_descriptionController.text.trim().isNotEmpty) {
        map['description'] = _descriptionController.text.trim();
      }
      if (_format != 'online' && _locationNameController.text.trim().isNotEmpty) {
        map['location_name'] = _locationNameController.text.trim();
        map['location_address'] = _locationAddressController.text.trim();
      }
      if (_format != 'offline' && _onlineUrlController.text.trim().isNotEmpty) {
        map['online_url'] = _onlineUrlController.text.trim();
      }

      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
      if (_startAt != null) map['start_at'] = fmt.format(_startAt!);
      if (_endAt != null) map['end_at'] = fmt.format(_endAt!);
      if (_regOpenAt != null) map['registration_open_at'] = fmt.format(_regOpenAt!);
      if (_regCloseAt != null) map['registration_close_at'] = fmt.format(_regCloseAt!);

      if (_quotaController.text.trim().isNotEmpty) {
        map['quota'] = int.tryParse(_quotaController.text.trim());
      }
      if (_waLinkController.text.trim().isNotEmpty) {
        map['wa_group_link'] = _waLinkController.text.trim();
      }
      if (_skpPointsController.text.trim().isNotEmpty) {
        map['skp_points'] = int.tryParse(_skpPointsController.text.trim());
      }

      if (_audience == 'restricted') {
        int facultyIdx = 0;
        for (final fid in _selectedFacultyIds) {
          map['faculty_ids[$facultyIdx]'] = fid;
          facultyIdx++;
        }
        int prodiIdx = 0;
        for (final pid in _selectedStudyProgramIds) {
          map['study_program_ids[$prodiIdx]'] = pid;
          prodiIdx++;
        }
        if (_cohortMin != null) map['cohort_min'] = _cohortMin;
        if (_cohortMax != null) map['cohort_max'] = _cohortMax;
      }

      if (_isPaid) {
        final rawPrice = _priceController.text.replaceAll('.', '').trim();
        map['price'] = int.tryParse(rawPrice) ?? 0;
        if (_bankNameController.text.trim().isNotEmpty) {
          map['payment_bank_name'] = _bankNameController.text.trim();
          map['payment_account_number'] = _accountNumberController.text.trim();
          map['payment_account_name'] = _accountNameController.text.trim();
        }
        if (_instructionsController.text.trim().isNotEmpty) {
          map['payment_instructions'] = _instructionsController.text.trim();
        }
      }

      if (_posterFile != null) {
        map['poster'] = await MultipartFile.fromFile(
          _posterFile!.path,
          filename: _posterFile!.path.split(Platform.pathSeparator).last,
        );
      }

      if (_isPaid && _qrisFile != null) {
        map['payment_qris'] = await MultipartFile.fromFile(
          _qrisFile!.path,
          filename: _qrisFile!.path.split(Platform.pathSeparator).last,
        );
      }

      if (widget.isEditing) {
        map['_method'] = 'PUT';
      }

      final formData = FormData.fromMap(map);
      final response = await ref
          .read(panitiaRemoteDataSourceProvider)
          .saveEvent(formData, eventId: widget.eventId);

      if (!mounted) return;

      AppHaptics.success();
      final msg = response['message'] as String? ??
          (widget.isEditing ? 'Acara berhasil diperbarui.' : 'Acara berhasil disimpan.');
      _snack(msg);

      ref.invalidate(panitiaEventsProvider);
      ref.invalidate(panitiaDashboardProvider);

      Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaAsync = ref.watch(panitiaEventsMetaProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isEditing ? 'Ubah Acara' : 'Buat Acara Baru',
          style: AppTypography.titleMedium,
        ),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator(color: AppColors.cobalt))
          : Column(
              children: [
                _buildStepperHeader(),
                Expanded(
                  child: metaAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.cobalt),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Gagal memuat master data: $err',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                      ),
                    ),
                    data: (meta) => PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1InfoAndPoster(meta.categories),
                        _buildStep2ScheduleAndLocation(),
                        _buildStep3AudienceAndQuota(meta.faculties, meta.studyPrograms),
                        _buildStep4PaymentAndPublish(),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['Info & Poster', 'Jadwal & Lokasi', 'Sasaran & Kuota', 'Biaya & Tiket'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.ink200, width: 1)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i < _currentStep) {
                    AppHaptics.selection();
                    setState(() => _currentStep = i);
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentStep
                            ? AppColors.cobalt
                            : (i < _currentStep ? AppColors.mint : AppColors.ink100),
                      ),
                      child: Center(
                        child: i < _currentStep
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: AppTypography.micro.copyWith(
                                  color: i == _currentStep ? Colors.white : AppColors.ink500,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.micro.copyWith(
                        color: i == _currentStep ? AppColors.cobalt : AppColors.ink500,
                        fontWeight: i == _currentStep ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 14,
                height: 2,
                color: i < _currentStep ? AppColors.mint : AppColors.ink200,
              ),
          ],
        ],
      ),
    );
  }

  // --- Step 1: Info & Poster ---
  Widget _buildStep1InfoAndPoster(List<PanitiaMetaItem> categories) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Poster Acara (Rasio 4:5)', style: AppTypography.label),
        const SizedBox(height: 4),
        Text(
          'Unggah gambar poster tegak dengan resolusi minimal 600x750 piksel (maks. 3 MB).',
          style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: GestureDetector(
            onTap: _pickPoster,
            child: Container(
              width: 180,
              height: 225, // 4:5 ratio
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                  color: _fieldErrors.containsKey('poster')
                      ? AppColors.danger
                      : AppColors.ink300,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadii.borderMd,
                child: _posterFile != null
                    ? Image.file(_posterFile!, fit: BoxFit.cover)
                    : (_existingPosterUrl != null && _existingPosterUrl!.isNotEmpty)
                        ? Image.network(_existingPosterUrl!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: AppColors.cobalt),
                              const SizedBox(height: 8),
                              Text('Pilih Gambar',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.cobalt, fontWeight: FontWeight.w700)),
                            ],
                          ),
              ),
            ),
          ),
        ),
        if (_fieldErrors.containsKey('poster')) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              _fieldErrors['poster']!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _titleController,
          label: 'Judul Acara *',
          hint: 'Contoh: Seminar Nasional AI & Masa Depan Karier Mahasiswa',
          fieldKey: 'title',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          controller: _slugController,
          label: 'Slug URL Kustom (Opsional)',
          hint: 'seminar-nasional-ai-2026',
          fieldKey: 'slug',
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Kategori Acara *', style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(
              color: _fieldErrors.containsKey('category_id')
                  ? AppColors.danger
                  : AppColors.ink300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedCategoryId,
              hint: const Text('Pilih Kategori'),
              items: categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.id,
                  child: Text(cat.name, style: AppTypography.bodyMedium),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                  _fieldErrors.remove('category_id');
                });
              },
            ),
          ),
        ),
        if (_fieldErrors.containsKey('category_id')) ...[
          const SizedBox(height: 4),
          Text(_fieldErrors['category_id']!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          controller: _summaryController,
          label: 'Ringkasan Singkat (Maks. 280 Karakter)',
          hint: 'Deskripsi satu paragraf untuk pratinjau kartu acara...',
          fieldKey: 'summary',
          maxLines: 2,
          maxLength: 280,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          controller: _descriptionController,
          label: 'Deskripsi Lengkap Acara',
          hint: 'Jelaskan latar belakang acara, pembicara, agenda, dll...',
          fieldKey: 'description',
          maxLines: 6,
        ),
      ],
    );
  }

  // --- Step 2: Format, Jadwal & Lokasi ---
  Widget _buildStep2ScheduleAndLocation() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Format Pelaksanaan *', style: AppTypography.label),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFormatChip('offline', 'Luring (Offline)', Icons.location_on_rounded),
            const SizedBox(width: 8),
            _buildFormatChip('online', 'Daring (Online)', Icons.videocam_rounded),
            const SizedBox(width: 8),
            _buildFormatChip('hybrid', 'Hybrid', Icons.hub_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_format != 'online') ...[
          _buildTextField(
            controller: _locationNameController,
            label: 'Nama Lokasi Tatap Muka *',
            hint: 'Contoh: Auditorium Tower Lt. 7 Kampus Meruya',
            fieldKey: 'location_name',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _locationAddressController,
            label: 'Alamat Lokasi',
            hint: 'Jl. Meruya Selatan No. 1, Kembangan, Jakarta Barat',
            fieldKey: 'location_address',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_format != 'offline') ...[
          _buildTextField(
            controller: _onlineUrlController,
            label: 'Tautan Acara Daring (Zoom / GMeet) *',
            hint: 'https://meet.google.com/...',
            fieldKey: 'online_url',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text('Jadwal Acara *', style: AppTypography.label),
        const SizedBox(height: 8),
        _buildDateTimeTile(
          label: 'Waktu Mulai Acara *',
          value: _startAt,
          onTap: () async {
            final dt = await _pickDateTime(_startAt);
            if (dt != null) setState(() => _startAt = dt);
          },
          fieldKey: 'start_at',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDateTimeTile(
          label: 'Waktu Selesai Acara *',
          value: _endAt,
          onTap: () async {
            final dt = await _pickDateTime(_endAt);
            if (dt != null) setState(() => _endAt = dt);
          },
          fieldKey: 'end_at',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Periode Pendaftaran (Opsional)', style: AppTypography.label),
        const SizedBox(height: 8),
        _buildDateTimeTile(
          label: 'Pendaftaran Dibuka',
          value: _regOpenAt,
          onTap: () async {
            final dt = await _pickDateTime(_regOpenAt);
            if (dt != null) setState(() => _regOpenAt = dt);
          },
          fieldKey: 'registration_open_at',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDateTimeTile(
          label: 'Pendaftaran Ditutup',
          value: _regCloseAt,
          onTap: () async {
            final dt = await _pickDateTime(_regCloseAt);
            if (dt != null) setState(() => _regCloseAt = dt);
          },
          fieldKey: 'registration_close_at',
        ),
      ],
    );
  }

  Widget _buildFormatChip(String value, String label, IconData icon) {
    final selected = _format == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          setState(() => _format = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.cobalt : AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(
              color: selected ? AppColors.cobalt : AppColors.ink300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.ink, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required String fieldKey,
  }) {
    final hasErr = _fieldErrors.containsKey(fieldKey);
    final text = value != null
        ? '${AppFormatters.eventDate(value)} · ${AppFormatters.eventTime(value)}'
        : 'Pilih waktu...';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: hasErr ? AppColors.danger : AppColors.ink300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                color: hasErr ? AppColors.danger : AppColors.cobalt, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
                  Text(
                    text,
                    style: AppTypography.bodySmall.copyWith(
                      color: value != null ? AppColors.ink : AppColors.ink400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.access_time_rounded, color: AppColors.ink400, size: 18),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Sasaran & Kuota ---
  Widget _buildStep3AudienceAndQuota(
    List<PanitiaMetaItem> faculties,
    List<PanitiaMetaItem> studyPrograms,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Sasaran Peserta *', style: AppTypography.label),
        const SizedBox(height: 8),
        _buildAudienceRadio(
          'umb_only',
          'Khusus Mahasiswa UMB',
          'Hanya mahasiswa aktif Universitas Mercu Buana dengan NIM terverifikasi.',
        ),
        const SizedBox(height: 8),
        _buildAudienceRadio(
          'public',
          'Terbuka untuk Umum',
          'Dapat diikuti mahasiswa kampus lain dan masyarakat umum.',
        ),
        const SizedBox(height: 8),
        _buildAudienceRadio(
          'restricted',
          'Terbatas Fakultas / Prodi / Angkatan',
          'Saring peserta berdasarkan fakultas asal, program studi, dan rentang tahun angkatan.',
        ),
        if (_audience == 'restricted') ...[
          const SizedBox(height: AppSpacing.md),
          Text('Batasi Fakultas (Pilih yang diizinkan):', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: faculties.map((fac) {
              final sel = _selectedFacultyIds.contains(fac.id);
              return FilterChip(
                label: Text(fac.name),
                selected: sel,
                selectedColor: AppColors.cobaltLight,
                checkmarkColor: AppColors.cobalt,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedFacultyIds.add(fac.id);
                    } else {
                      _selectedFacultyIds.remove(fac.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Batasi Program Studi (Opsional):', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: studyPrograms.map((prodi) {
              final sel = _selectedStudyProgramIds.contains(prodi.id);
              return FilterChip(
                label: Text(prodi.name),
                selected: sel,
                selectedColor: AppColors.cobaltLight,
                checkmarkColor: AppColors.cobalt,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedStudyProgramIds.add(prodi.id);
                    } else {
                      _selectedStudyProgramIds.remove(prodi.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildCohortDropdown(
                  'Angkatan Minimal',
                  _cohortMin,
                  (val) => setState(() => _cohortMin = val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _cohortDropdownMax(),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _quotaController,
          label: 'Kuota Maksimal Peserta',
          hint: 'Contoh: 150',
          fieldKey: 'quota',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          controller: _waLinkController,
          label: 'Tautan Grup WhatsApp (chat.whatsapp.com)',
          hint: 'https://chat.whatsapp.com/ABC123xyz',
          fieldKey: 'wa_group_link',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _skpPointsController,
                label: 'Poin SKP (Opsional)',
                hint: 'Contoh: 2',
                fieldKey: 'skp_points',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SwitchListTile(
                title: Text('E-Sertifikat', style: AppTypography.labelSmall),
                subtitle: Text('Diberikan ke peserta', style: AppTypography.micro),
                value: _certificateProvided,
                activeColor: AppColors.cobalt,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _certificateProvided = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudienceRadio(String value, String title, String subtitle) {
    final selected = _audience == value;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() => _audience = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.cobaltLight : AppColors.surface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: selected ? AppColors.cobalt : AppColors.ink200,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.cobalt : AppColors.ink400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: selected ? AppColors.cobalt : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortDropdown(String label, int? selected, ValueChanged<int?> onChanged) {
    final currentYear = DateTime.now().year;
    final years = List.generate(8, (i) => currentYear - 5 + i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.ink300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selected,
              hint: const Text('Semua'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Semua')),
                ...years.map((y) => DropdownMenuItem<int>(value: y, child: Text('$y'))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cohortDropdownMax() {
    return _buildCohortDropdown(
      'Angkatan Maksimal',
      _cohortMax,
      (val) => setState(() => _cohortMax = val),
    );
  }

  // --- Step 4: Biaya & Tiket ---
  Widget _buildStep4PaymentAndPublish() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Tipe Tiket Acara *', style: AppTypography.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isPaid = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_isPaid ? AppColors.cobalt : AppColors.surface,
                    borderRadius: AppRadii.borderMd,
                    border: Border.all(
                      color: !_isPaid ? AppColors.cobalt : AppColors.ink300,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Gratis (Rp 0)',
                      style: AppTypography.label.copyWith(
                        color: !_isPaid ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isPaid = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isPaid ? AppColors.cobalt : AppColors.surface,
                    borderRadius: AppRadii.borderMd,
                    border: Border.all(
                      color: _isPaid ? AppColors.cobalt : AppColors.ink300,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Berbayar',
                      style: AppTypography.label.copyWith(
                        color: _isPaid ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isPaid) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _priceController,
            label: 'Harga Tiket (Rp 1.000 s.d. Rp 10.000.000) *',
            hint: 'Contoh: 50000',
            fieldKey: 'price',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            title: Text('Kode Unik Transfer (3-digit)', style: AppTypography.labelSmall),
            subtitle: Text(
              'Menambahkan 3 digit acak (cth: Rp 50.137) agar verifikasi manual otomatis presisi.',
              style: AppTypography.micro,
            ),
            value: _useUniqueCode,
            activeColor: AppColors.cobalt,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _useUniqueCode = val),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Rekening Pembayaran Bank Panitia', style: AppTypography.label),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _bankNameController,
            label: 'Nama Bank (BCA / Mandiri / BNI / BRI)',
            hint: 'Contoh: Bank Central Asia (BCA)',
            fieldKey: 'payment_bank_name',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(
            controller: _accountNumberController,
            label: 'Nomor Rekening',
            hint: 'Contoh: 8410293810',
            fieldKey: 'payment_account_number',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(
            controller: _accountNameController,
            label: 'Atas Nama Rekening',
            hint: 'Contoh: BEM FASILKOM UMB',
            fieldKey: 'payment_account_name',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Gambar QRIS Panitia (Opsional)', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickQris,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: AppRadii.borderMd,
                border: Border.all(color: AppColors.ink300),
              ),
              child: ClipRRect(
                borderRadius: AppRadii.borderMd,
                child: _qrisFile != null
                    ? Image.file(_qrisFile!, fit: BoxFit.contain)
                    : (_existingQrisUrl != null && _existingQrisUrl!.isNotEmpty)
                        ? Image.network(_existingQrisUrl!, fit: BoxFit.contain)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2_rounded,
                                    size: 32, color: AppColors.cobalt),
                                const SizedBox(height: 4),
                                Text('Unggah Barcode QRIS',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.cobalt, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _instructionsController,
            label: 'Petunjuk Pembayaran Tambahan',
            hint: 'Mohon cantumkan berita transfer: TK-NAMA...',
            fieldKey: 'payment_instructions',
            maxLines: 3,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.ink200, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.cobalt),
                  const SizedBox(width: 8),
                  Text('Siap Simpan Acara', style: AppTypography.label),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Anda dapat menyimpan acara sebagai "Draf" terlebih dahulu untuk ditinjau, atau langsung "Publikasikan" agar langsung tayang di katalog mahasiswa.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String fieldKey,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTypography.bodyMedium,
          onChanged: (_) {
            if (_fieldErrors.containsKey(fieldKey)) {
              setState(() => _fieldErrors.remove(fieldKey));
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.ink400),
            filled: true,
            fillColor: AppColors.surface,
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.liftedCard,
        border: const Border(top: BorderSide(color: AppColors.ink200, width: 1)),
      ),
      child: SafeArea(
        child: _currentStep < 3
            ? Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                      ),
                      child: const Text('Kembali'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cobalt,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lanjut'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => _submit(publishNow: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan Draf'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : () => _submit(publishNow: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cobalt,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publikasikan'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
