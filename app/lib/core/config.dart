/// Global app configuration.
///
/// While the Laravel backend is not ready the app runs on built-in demo data.
/// When the API is live, set [useDemoData] to false and point [apiBaseUrl]
/// at the Laravel server (see docs/FEATURES.md → Technical Contract).
class AppConfig {
  static const bool useDemoData = bool.fromEnvironment('DEMO', defaultValue: true);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com/api/v1',
  );

  /// Agora App ID for live voice (set at build time with --dart-define).
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');
}
