import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// SC-02: Scan Tagihan Listrik (docs/SCREEN_INVENTORY.md §SC-02)
class ScanTagihanScreen extends StatefulWidget {
  const ScanTagihanScreen({super.key});

  @override
  State<ScanTagihanScreen> createState() => _ScanTagihanScreenState();
}

class _ScanTagihanScreenState extends State<ScanTagihanScreen> {
  bool _isAnalysing = false;

  Future<void> _simulateScan() async {
    setState(() => _isAnalysing = true);

    // Fake processing time (DEMO_SIMULATION)
    await Future<void>.delayed(AppDurations.simulatedScan);

    if (!mounted) return;

    // Navigate to SC-03
    context.pushReplacement(AppRoute.energyAnalysis);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalysing) {
      return const AppScaffold(
        body: LoadingState(label: 'Menganalisis tagihan...'),
      );
    }

    return AppScaffold(
      title: 'Scan Tagihan Listrik',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Unggah atau scan tagihan listrik PLN bulan ini untuk melihat analisis pemakaian dan rekomendasi penghematan energi.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: 'Ambil Foto Tagihan',
            onPressed: _simulateScan,
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Unggah dari Galeri',
            onPressed: _simulateScan,
          ),
        ],
      ),
    );
  }
}
