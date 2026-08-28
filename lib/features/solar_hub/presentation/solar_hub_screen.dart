import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// SC-04: Solar Hub — Scan Atap (docs/SCREEN_INVENTORY.md §SC-04)
class SolarHubScreen extends StatefulWidget {
  const SolarHubScreen({super.key});

  @override
  State<SolarHubScreen> createState() => _SolarHubScreenState();
}

class _SolarHubScreenState extends State<SolarHubScreen> {
  bool _isScanning = false;

  Future<void> _simulateScan() async {
    setState(() => _isScanning = true);

    // Fake processing time (DEMO_SIMULATION)
    await Future<void>.delayed(AppDurations.simulatedScan);

    if (!mounted) return;

    setState(() => _isScanning = false);

    // Navigate to SC-05
    context.push(AppRoute.radarAtap);
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return const AppScaffold(body: LoadingState(label: 'Memindai atap...'));
    }

    return AppScaffold(
      title: 'Solar Hub',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Icon(Icons.roofing_outlined, size: 80, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Scan atap rumah Anda untuk melihat potensi pemasangan Solar Hub komunitas dan kapasitas energi yang bisa didapatkan.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: 'Scan Sekarang',
            onPressed: _simulateScan,
          ),
        ],
      ),
    );
  }
}
