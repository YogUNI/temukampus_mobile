import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/ticket_clipper.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Tiket Saya', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiket Acara Aktif', style: AppTypography.titleSmall),
            const SizedBox(height: 12),
            TicketContainer(
              punchRadius: 12,
              punchPositionPercent: 0.65,
              borderColor: AppColors.ink,
              borderWidth: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('TK-7F3KQ9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        StatusPill(status: RegistrationStatusType.confirmed, isStamp: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seminar Nasional: Masa Depan Artificial Intelligence',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    const DottedTearLine(color: AppColors.ink200),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jumat, 20 Nov 2026', style: AppTypography.bodySmall),
                        Text('Tower Lt. 7 Meruya', style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

