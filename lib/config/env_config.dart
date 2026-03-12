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
}
