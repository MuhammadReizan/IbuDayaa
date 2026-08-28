import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// SC-14: Ambil Kuota (Bottom Sheet)
class TakeOfferSheet extends ConsumerStatefulWidget {
  const TakeOfferSheet({super.key, required this.offer});

  final DemoQuotaOffer offer;

  @override
  ConsumerState<TakeOfferSheet> createState() => _TakeOfferSheetState();
}

class _TakeOfferSheetState extends ConsumerState<TakeOfferSheet> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ambil Kuota', style: text.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Anda akan mengambil kuota dari ${widget.offer.ownerName}',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jumlah Kuota', style: text.bodyMedium),
                Text(
                  '${widget.offer.amountKwh.toStringAsFixed(1)} kWh',
                  style: text.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Catatan (Opsional)',
              hintText: 'Misal: Terima kasih!',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Konfirmasi Ambil',
            onPressed: () {
              ref
                  .read(demoRepositoryProvider)
                  .takeOffer(
                    widget.offer.id,
                    note: _noteController.text.trim(),
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil mengambil kuota dari ${widget.offer.ownerName}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
