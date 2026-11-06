import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Jelajah Acara', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cobaltLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.explore_rounded, color: AppColors.cobalt, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Katalog Eksplorasi Acara', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Fitur pencarian filter mendalam (Kategori, SKP, Organisasi Ormawa) siap dirilis pada modul acara berikutnya.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

