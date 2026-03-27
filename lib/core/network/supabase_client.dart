import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// SupabaseClientProvider – Singleton access to Supabase
// ============================================================

/// Thin wrapper that exposes the Supabase client initialised in `main.dart`.
///
/// Modules should depend on this instead of calling
/// `Supabase.instance.client` directly so we can swap implementations
/// during testing.
class SupabaseClientProvider {
  SupabaseClientProvider._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;
}
