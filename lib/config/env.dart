/// Compile-time environment variables for API integration.
///
/// Values are injected via `--dart-define` or `--dart-define-from-file`.
/// Every value has a sensible default so hot reload still works without
/// additional flags.
class EnvConfig {
  EnvConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2/api',
  );

  // Allows overriding the full endpoint if needed (e.g., temporary routes).
  static const authCheckEndpoint = String.fromEnvironment(
    'AUTH_CHECK_ENDPOINT',
    defaultValue: '$apiBaseUrl/auth/check',
  );

  static const signUpEndpoint = String.fromEnvironment(
    'SIGN_UP_ENDPOINT',
    defaultValue: '$apiBaseUrl/signup',
  );
}
