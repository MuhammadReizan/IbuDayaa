import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../application/arisan_providers.dart';

/// SC-13: Bagikan Kuota
class ShareQuotaScreen extends ConsumerStatefulWidget {
  const ShareQuotaScreen({super.key});

  @override
  ConsumerState<ShareQuotaScreen> createState() => _ShareQuotaScreenState();
}

class _ShareQuotaScreenState extends ConsumerState<ShareQuotaScreen> {
  double _amount = 1.0;
  String _slotLabel = 'Sabtu, 08.00–10.00';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DemoEnergyQuota quota = ref.watch(energyQuotaProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Bagikan Kuota',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Tinjau & Bagikan',
        onPressed: _amount > quota.availableKwh
            ? null
            : () {
                ref
                    .read(demoRepositoryProvider)
                    .shareQuota(
                      kwh: _amount,
                      slotLabel: _slotLabel,
                      note: _noteController.text.trim(),
                    );
                context.pushReplacement(AppRoute.offerPublishedPath);
              },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kuota Tersedia', style: text.bodyMedium),
                Text(
                  '${quota.availableKwh.toStringAsFixed(1)} kWh',
                  style: text.titleMedium?.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Jumlah Kuota (kWh)', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [1.0, 2.0, 3.0].map((a) {
              final selected = _amount == a;
              return ChoiceChip(
                label: Text('${a.toStringAsFixed(1)} kWh'),
                selected: selected,
                onSelected: a <= quota.availableKwh
                    ? (v) => setState(() => _amount = a)
                    : null,
              );
            }).toList(),
          ),
          if (_amount > quota.availableKwh) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Kuota tidak mencukupi.',
              style: text.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Slot Waktu (Opsional)', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: _slotLabel,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              'Sabtu, 08.00–10.00',
              'Sabtu, 10.00–12.00',
              'Sabtu, 13.00–15.00',
              'Minggu, 08.00–10.00',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _slotLabel = v);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Catatan Tambahan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Misal: Sisa kuota minggu ini, silakan yang butuh.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
