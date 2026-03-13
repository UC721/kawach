/// Centralised environment config for KAWACH.
///
/// Keys are injected via --dart-define at build time, e.g.
///   flutter run --dart-define=MAPS_API_KEY=YOUR_KEY_HERE
///
/// For local development the key is also stored in .env (gitignored).
/// In CI/CD set these as environment secrets instead.
library;

class EnvConfig {
  // Google Maps API key (set via --dart-define=MAPS_API_KEY=xxx)
  static const String mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyBp4BKTYFkYkVWxdOg9tYSJKJLMkHjC7jo',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vzmnjviiulxajxrabdyt.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6bW5qdmlpdWx4YWp4cmFiZHl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMzk1NjgsImV4cCI6MjA4ODkxNTU2OH0.IwFHQE2falwxBJf6sWSrjD586lwrKhjyxgb-5KNby0s',
  );
}
