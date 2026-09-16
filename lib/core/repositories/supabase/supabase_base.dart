import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors.dart';

/// Shared plumbing for Supabase repositories: the client, table shortcuts,
/// and error mapping.
///
/// Every `raise exception '...'` in `supabase/migrations/` is already
/// phrased in plain Indonesian for the end user (the same bar the local
/// repositories hold their [AppException] messages to), so a
/// [PostgrestException] from an RPC call can be shown as-is. A missing
/// network connection or an unexpected shape gets a generic message instead
/// of a raw exception the user cannot act on.
abstract class SupabaseRepo {
  SupabaseRepo(this.client);

  final SupabaseClient client;

  PostgrestQueryBuilder table(String name) => client.from(name);

  /// Runs [body], turning any Supabase/network failure into an
  /// [AppException] with a message the user can read.
  Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException catch (e) {
      // Postgres RAISE EXCEPTION messages are already end-user Indonesian
      // (see supabase/migrations); a bare constraint violation is not, so it
      // gets a generic fallback instead of leaking column/table names.
      final msg = e.message.trim();
      final looksLikeUserMessage =
          msg.isNotEmpty &&
          !msg.startsWith('duplicate key') &&
          !msg.contains('violates');
      throw AppException(
        looksLikeUserMessage
            ? msg
            : 'Permintaan tidak bisa diproses. Coba lagi.',
      );
    } on AuthException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw const AppException(
        'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}
