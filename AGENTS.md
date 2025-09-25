# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains Dart source (widgets, state, services). Group features into subdirectories such as `lib/ledger/` with entry models and views. Platform shells live in `android/`, `ios/`, `macos/`, `linux/`, `windows/`, and `web/`; edit these only for platform-specific integrations. Shared configuration and lint rules reside at the repo root (`pubspec.yaml`, `analysis_options.yaml`). Place integration fixtures or mock assets under `test/fixtures/` to keep the main `test/` tree focused on Dart unit tests.

## Build, Test, and Development Commands
`flutter pub get` resolves dependencies before any other command. `flutter analyze` runs static checks enforced by `flutter_lints`. `flutter test` executes the automated test suite. Use `flutter run -d chrome` for quick web iteration or swap the device id (e.g., `-d ios`) for platform targets. Build artifacts use `flutter build <platform>`; for example, `flutter build apk` produces the Android package.

## Coding Style & Naming Conventions
Follow the defaults from `package:flutter_lints`: 2-space indentation, trailing commas on multi-line collections, and single quotes unless interpolation is required. Name files in `lib/` and `test/` with `snake_case.dart`. Classes and enums use PascalCase, while methods, variables, and test descriptions stay lowerCamelCase. Run `dart format .` before committing.

## Testing Guidelines
Write widget and unit tests with the `flutter_test` package. Mirror each production file with a sibling test file (e.g., `lib/ledger/entry_view.dart` → `test/ledger/entry_view_test.dart`). Group tests using `group()` and prefer descriptive `test()` names such as `test('saves ledger entry when form is valid', ...)`. Aim for meaningful coverage on critical ledger flows before merging.

## Commit & Pull Request Guidelines
Keep commits focused and use imperative mood summaries (e.g., `feat: add ledger entry form`). Reference related issues in the body. For pull requests, include: problem statement, solution overview, screenshots or screen recordings for UI changes, and explicit test evidence (`flutter test` output or manual QA notes). Request review from another agent before merging and ensure CI (if configured) is green.
