import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/event_model.dart';

/// Bottom sheet filter Jelajah v2.
///
/// Tambahan dibanding versi lama: slider rentang harga, chips ormawa,
/// dan hitungan filter aktif pada tombol terapkan.
class EventFilterSheet extends StatefulWidget {
  final String? initialFormat;
  final bool initialOnlyFree;
  final bool initialOnlySkp;
  final bool initialSuitableForMe;
  final int? initialMaxPrice;
  final Set<String> initialOrganizationSlugs;

  /// Ormawa yang bisa dipilih (diturunkan dari katalog saat ini).
  final List<EventOrganizationModel> availableOrganizations;

  /// Batas atas slider harga (dipiih dari harga acara termahal di katalog).
  final int maxPriceLimit;

  final void Function({
    required String? format,
    required bool onlyFree,
    required bool onlySkp,
    required bool suitableForMe,
    required int? maxPrice,
    required Set<String> organizationSlugs,
  }) onApply;

  final VoidCallback onReset;

  const EventFilterSheet({
    super.key,
    required this.initialFormat,
    required this.initialOnlyFree,
    required this.initialOnlySkp,
    required this.initialSuitableForMe,
    this.initialMaxPrice,
    this.initialOrganizationSlugs = const {},
    this.availableOrganizations = const [],
    this.maxPriceLimit = 500000,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late String? _selectedFormat;
  late bool _onlyFree;
  late bool _onlySkp;
  late bool _suitableForMe;
  late int? _maxPrice;
  late Set<String> _orgs;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _onlyFree = widget.initialOnlyFree;
    _onlySkp = widget.initialOnlySkp;
    _suitableForMe = widget.initialSuitableForMe;
    _maxPrice = widget.initialMaxPrice;
    _orgs = {...widget.initialOrganizationSlugs};
  }

  int get _activeCount {
    var count = 0;
    if (_selectedFormat != null) count++;
    if (_onlyFree) count++;
    if (_onlySkp) count++;
    if (_suitableForMe) count++;
    if (_maxPrice != null) count++;
    if (_orgs.isNotEmpty) count++;
    return count;
  }

  void _reset() {
    setState(() {
      _selectedFormat = null;
      _onlyFree = false;
      _onlySkp = false;
      _suitableForMe = false;
      _maxPrice = null;
      _orgs = {};
    });
    widget.onReset();
    Navigator.pop(context);
  }

  void _apply() {
    AppHaptics.selection();
    widget.onApply(
      format: _selectedFormat,
      onlyFree: _onlyFree,
      onlySkp: _onlySkp,
      suitableForMe: _suitableForMe,
      maxPrice: _maxPrice,
      organizationSlugs: _orgs,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink200,
                  borderRadius: AppRadii.borderPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Acara Kampus', style: AppTypography.titleMedium),
                        TextButton(
                          onPressed: _reset,
                          child: Text(
                            'Reset Semua',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.dangerText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xl),

                    // 1. Format
                    Text('Format Pelaksanaan', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildChip('Semua Format', null, _selectedFormat == null),
                        _buildChip('Tatap Muka (Offline)', 'offline', _selectedFormat == 'offline'),
                        _buildChip('Daring (Online)', 'online', _selectedFormat == 'online'),
                        _buildChip('Hybrid', 'hybrid', _selectedFormat == 'hybrid'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 2. Biaya
                    Text('Biaya Pendaftaran', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleCard(
                            title: 'Semua Biaya',
                            isSelected: !_onlyFree,
                            onTap: () {
                              AppHaptics.light();
                              setState(() => _onlyFree = false);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildToggleCard(
                            title: 'Gratis Saja',
                            isSelected: _onlyFree,
                            onTap: () {
                              AppHaptics.light();
                              setState(() => _onlyFree = true);
                            },
                          ),
                        ),
                      ],
                    ),

                    // 2b. Slider rentang harga (sembunyi saat "Gratis Saja")
                    if (!_onlyFree) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text('Rentang Harga', style: AppTypography.label),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cobaltLight,
                              borderRadius: AppRadii.borderXs,
                            ),
                            child: Text(
                              _maxPrice == null
                                  ? 'Semua'
                                  : 'Rp 0–${AppFormatters.compactRupiah(_maxPrice!)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.cobalt,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(0, (_maxPrice ?? widget.maxPriceLimit).toDouble()),
                        min: 0,
                        max: widget.maxPriceLimit.toDouble(),
                        divisions: 20,
                        activeColor: AppColors.cobalt,
                        inactiveColor: AppColors.ink100,
                        labels: RangeLabels('Rp 0', 'Rp ${(_maxPrice ?? widget.maxPriceLimit)}'),
                        onChanged: (values) =>
                            setState(() => _maxPrice = values.end.round()),
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _buildPricePreset('Semua', null),
                          _buildPricePreset('≤ Rp 50rb', 50000),
                          _buildPricePreset('≤ Rp 100rb', 100000),
                          _buildPricePreset('≤ Rp 250rb', 250000),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),

                    // 3. SKP & Kesesuaian
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.cobalt,
                      title: Text('Hanya Acara Ber-SKP', style: AppTypography.label),
                      subtitle: Text(
                        'Acara yang menyertakan poin SKP/SKPI mahasiswa',
                        style: AppTypography.bodySmall,
                      ),
                      value: _onlySkp,
                      onChanged: (val) => setState(() => _onlySkp = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.cobalt,
                      title: Text('Cocok untuk Jurusan Saya', style: AppTypography.label),
                      subtitle: Text(
                        'Menyaring acara yang terbuka untuk fakultas & prodiku',
                        style: AppTypography.bodySmall,
                      ),
                      value: _suitableForMe,
                      onChanged: (val) => setState(() => _suitableForMe = val),
                    ),

                    // 4. Ormawa
                    if (widget.availableOrganizations.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('Ormawa Penyelenggara', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _buildOrgChip('Semua Ormawa', null),
                          for (final org in widget.availableOrganizations)
                            _buildOrgChip(org.name, org.slug),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // 5. Footer sticky
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.ink100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StickerButton(
                      label: 'Reset',
                      variant: StickerButtonVariant.outline,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: StickerButton(
                      label: _activeCount == 0 ? 'Terapkan' : 'Terapkan ($_activeCount)',
                      variant: StickerButtonVariant.primary,
                      onPressed: _apply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String? value, bool isSelected) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        setState(() => _selectedFormat = value);
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobaltLight : AppColors.surface,
          borderRadius: AppRadii.borderPill,
          border: Border.all(
            color: isSelected ? AppColors.cobalt : AppColors.ink200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.cobalt : AppColors.ink700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobaltLight : AppColors.surface,
          borderRadius: AppRadii.borderSm,
          border: Border.all(
            color: isSelected ? AppColors.cobalt : AppColors.ink200,
          ),
        ),
        child: Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.cobalt : AppColors.ink700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPricePreset(String label, int? value) {
    final isSelected = _maxPrice == value;
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        setState(() => _maxPrice = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surface,
          borderRadius: AppRadii.borderPill,
          border: Border.all(color: isSelected ? AppColors.ink : AppColors.ink200),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.ink700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrgChip(String label, String? slug) {
    final isSelected = slug == null ? _orgs.isEmpty : _orgs.contains(slug);
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        setState(() {
          if (slug == null) {
            _orgs = {};
          } else {
            _orgs.contains(slug) ? _orgs.remove(slug) : _orgs.add(slug);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobalt : AppColors.surface,
          borderRadius: AppRadii.borderPill,
          border: Border.all(color: isSelected ? AppColors.cobalt : AppColors.ink200),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.ink700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}