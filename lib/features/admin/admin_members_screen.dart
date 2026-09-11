import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final engine = ref.read(creditScoringEngineProvider);
    final text = Theme.of(context).textTheme;
    final q = _query.toLowerCase();
    final members = data.memberProfiles
        .where(
          (m) =>
              q.isEmpty ||
              m.fullName.toLowerCase().contains(q) ||
              m.businessName.toLowerCase().contains(q),
        )
        .toList();

    return AppScaffold(
      title: 'Anggota',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau usaha',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.memberProfiles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyState(
                motif: BrandArtMotif.community,
                title: 'Belum ada anggota',
                message:
                    'Bagikan kode koperasi ${data.cooperative?.inviteCode ?? ''} '
                    'agar anggota bisa mendaftar.',
              ),
            )
          else
            for (final m in members) ...[
              Builder(
                builder: (context) {
                  final score = data.scoreOf(m.id, now, engine);
                  final months = monthlyUsage(data.recordsOf(m.id)).length;
                  final active = data.activeLoanOf(m.id);
                  return SectionCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onTap: () => context.push(Paths.adminMember(m.id)),
                    child: Row(
                      children: [
                        MemberAvatar(name: m.fullName, size: 44),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.fullName, style: text.titleSmall),
                              Text(
                                '${m.businessName} · $months bln tercatat',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusPill(
                              label: score == null
                                  ? 'Belum ada skor'
                                  : 'Skor ${score.score}',
                              tone: score == null
                                  ? PillTone.neutral
                                  : PillTone.info,
                            ),
                            if (active != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              StatusPill(
                                label: active.status.label,
                                tone: PillTone.solar,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
