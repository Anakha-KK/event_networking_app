# event_networking_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment configuration

API URLs are injected at build time so each teammate can point the app at
their own Laravel container or a shared environment.

1. Copy `env/local.example.json` to `env/local.json` (ignored by Git) and edit
   the URLs as needed.
2. Run the app with the config file:

   ```bash
   flutter run --dart-define-from-file=env/local.json
   ```

   To use the shared presets, swap the filename for `env/dev.json` or
   `env/prod.json`.

Under the hood these values populate `EnvConfig` (`lib/config/env.dart`), so
widgets can read `EnvConfig.apiBaseUrl`/`EnvConfig.authCheckEndpoint` without
hardcoding URLs.
