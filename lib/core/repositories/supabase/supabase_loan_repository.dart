import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Every write is a `security definer` RPC — in particular `submit` calls
/// `submit_loan` (`supabase/migrations`), which recomputes the credit score
/// from stored data server-side. A modified client cannot submit with a
/// score or eligibility it made up, the same guarantee
/// [LocalLoanRepository] gives by computing the score itself before
/// inserting.
class SupabaseLoanRepository extends SupabaseRepo implements LoanRepository {
  SupabaseLoanRepository(super.client);

  @override
  Future<LoanApplication> submit({
    required Profile me,
    required int amountIdr,
    required LoanPurpose purpose,
    required int tenorMonths,
    String? note,
  }) => guard(() async {
    final row = await client.rpc(
      'submit_loan',
      params: {
        'p_amount': amountIdr,
        'p_purpose': purpose.db,
        'p_tenor': tenorMonths,
        'p_note': note,
      },
    );
    return LoanApplication.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<void> cancel({required Profile me, required String loanId}) =>
      guard(() => client.rpc('cancel_loan', params: {'p_loan': loanId}));

  @override
  Future<void> startReview({required Profile admin, required String loanId}) =>
      guard(
        () => client.rpc(
          'admin_loan_action',
          params: {'p_loan': loanId, 'p_action': 'start_review'},
        ),
      );

  @override
  Future<void> approve({
    required Profile admin,
    required String loanId,
    String? note,
  }) => guard(
    () => client.rpc(
      'admin_loan_action',
      params: {'p_loan': loanId, 'p_action': 'approve', 'p_note': note},
    ),
  );

  @override
  Future<void> reject({
    required Profile admin,
    required String loanId,
    required String reason,
  }) => guard(
    () => client.rpc(
      'admin_loan_action',
      params: {'p_loan': loanId, 'p_action': 'reject', 'p_note': reason},
    ),
  );

  @override
  Future<void> disburse({required Profile admin, required String loanId}) =>
      guard(
        () => client.rpc(
          'admin_loan_action',
          params: {'p_loan': loanId, 'p_action': 'disburse'},
        ),
      );

  @override
  Future<void> markInstallmentPaid({
    required Profile admin,
    required String installmentId,
  }) => guard(
    () => client.rpc(
      'mark_installment_paid',
      params: {'p_installment': installmentId},
    ),
  );
}
