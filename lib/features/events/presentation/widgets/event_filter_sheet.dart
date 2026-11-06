import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';

class EventFilterSheet extends StatefulWidget {
  final String? initialFormat;
  final bool initialOnlyFree;
  final bool initialOnlySkp;
  final bool initialSuitableForMe;
  final void Function({
    required String? format,
    required bool onlyFree,
    required bool onlySkp,
    required bool suitableForMe,
  }) onApply;
  final VoidCallback onReset;

  const EventFilterSheet({
    super.key,
    required this.initialFormat,
    required this.initialOnlyFree,
    required this.initialOnlySkp,
    required this.initialSuitableForMe,
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

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _onlyFree = widget.initialOnlyFree;
    _onlySkp = widget.initialOnlySkp;
    _suitableForMe = widget.initialSuitableForMe;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Acara Kampus', style: AppTypography.titleMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFormat = null;
                        _onlyFree = false;
                        _onlySkp = false;
                        _suitableForMe = false;
                      });
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset Semua',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.dangerText),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Format Acara
              Text('Format Pelaksanaan', style: AppTypography.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFormatChip('Semua Format', null),
                  _buildFormatChip('Tatap Muka (Offline)', 'offline'),
                  _buildFormatChip('Daring (Online)', 'online'),
                  _buildFormatChip('Hybrid', 'hybrid'),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Biaya Pendaftaran
              Text('Biaya Pendaftaran', style: AppTypography.label),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleCard(
                      title: 'Semua Biaya',
                      isSelected: !_onlyFree,
                      onTap: () => setState(() => _onlyFree = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildToggleCard(
                      title: 'Gratis Saja',
                      isSelected: _onlyFree,
                      onTap: () => setState(() => _onlyFree = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Poin SKP & Kesesuaian Jurusan Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.cobalt,
                title: Text('Hanya Acara Ber-SKP', style: AppTypography.label),
                subtitle: Text('Acara yang menyertakan poin SKP/SKPI mahasiswa', style: AppTypography.bodySmall),
                value: _onlySkp,
                onChanged: (val) => setState(() => _onlySkp = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.cobalt,
                title: Text('Cocok untuk Jurusan Saya', style: AppTypography.label),
                subtitle: Text('Menyaring acara yang terbuka untuk fakultas & prodiku', style: AppTypography.bodySmall),
                value: _suitableForMe,
                onChanged: (val) => setState(() => _suitableForMe = val),
              ),
              const SizedBox(height: 24),

              // Tombol Terapkan
              StickerButton(
                label: 'Terapkan Filter',
                variant: StickerButtonVariant.primary,
                onPressed: () {
                  widget.onApply(
                    format: _selectedFormat,
                    onlyFree: _onlyFree,
                    onlySkp: _onlySkp,
                    suitableForMe: _suitableForMe,
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label, String? formatValue) {
    final isSelected = _selectedFormat == formatValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = formatValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobaltLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.cobalt : AppColors.ink200,
            width: isSelected ? 1.5 : 1,
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobaltLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.cobalt : AppColors.ink200,
            width: isSelected ? 1.5 : 1,
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
}
