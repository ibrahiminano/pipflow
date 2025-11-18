### 🔄 Project Awareness & Context
- **Always read `MIGRATION_PLAN.md`** at the start of a new conversation to understand the project's architecture, migration status, and goals.
- **Check `TASK.md`** before starting a new task. If the task isn't listed, add it with a brief description and today's date.
- **Use consistent naming conventions, file structure, and architecture patterns** as described in `MIGRATION_PLAN.md`.
- **Follow Clean Architecture + DDD principles** for all implementations.

### 🧱 Code Structure & Modularity
- **Never create a file longer than 500 lines of code.** If a file approaches this limit, refactor by splitting it into modules or helper widgets.
- **Organize code into clearly separated modules**, grouped by feature and layer:
  For features this looks like:
    - `domain/entities/` - Business models and entities
    - `domain/repositories/` - Repository interfaces
    - `data/models/` - Data transfer objects and models
    - `data/repositories/` - Repository implementations
    - `data/services/` - External service integrations
    - `presentation/screens/` - Screen widgets
    - `presentation/widgets/` - Reusable widget components
    - `presentation/providers/` - Riverpod providers
- **Use clear, consistent imports** (prefer relative imports within features).
- **Extract widgets** when they exceed 150 lines or become reusable.
- **Use flutter_dotenv** for environment variables.

### 🧪 Testing & Reliability
- **Always create widget and unit tests for new features** (widgets, providers, services).
- **After updating any logic**, check whether existing tests need to be updated. If so, do it.
- **Tests should live in a `/test` folder** mirroring the lib structure.
  - Include at least:
    - 1 widget test for UI components
    - 1 unit test for business logic
    - 1 integration test for critical flows
- **Use `mockito` or `mocktail`** for mocking dependencies.
- **Run `flutter test`** before marking any task complete.

### ✅ Task Completion
- **Update `MIGRATION_PLAN.md`** after completing each phase.
- **Mark completed tasks with checkboxes** [x] in the plan.
- Add new sub-tasks or TODOs discovered during development under the relevant phase.
- **Run the app on iOS simulator** to verify functionality before marking complete.

### 📎 Style & Conventions
- **Use Dart** as the primary language.
- **Follow Effective Dart** guidelines and use `flutter analyze`.
- **Use `freezed` for immutable models** with code generation.
- **Use `Riverpod` with code generation** for state management.
- **Format code with `dart format`** (line length: 100).
- Write **documentation comments for public APIs**:
  ```dart
  /// Brief description of what this does.
  ///
  /// Longer description if needed.
  /// 
  /// Example:
  /// ```dart
  /// final result = myFunction(param);
  /// ```
  class MyClass {
    /// Description of the method.
    ///
    /// [param1] - Description of parameter.
    /// Returns description of return value.
    String myMethod(String param1) {
      // Implementation
    }
  }
  ```

### 📚 Documentation & Explainability
- **Update `README.md`** when new features are added, dependencies change, or setup steps are modified.
- **Comment non-obvious code** and ensure everything is understandable to a mid-level Flutter developer.
- When writing complex logic, **add inline comments** explaining the why, not just the what.
- **Document API integrations** with rate limits and authentication details.

### 🧠 AI Behavior Rules
- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate packages** – only use verified packages from pub.dev.
- **Always check file paths and class names** exist before referencing them in code.
- **Never delete or overwrite existing code** unless explicitly instructed.
- **Always check official Flutter/Dart documentation** for the latest best practices.

### 🎨 UI/UX Guidelines
- **Follow Material Design 3** guidelines for Android.
- **Follow iOS Human Interface Guidelines** for iOS-specific components.
- **Use adaptive widgets** when platform-specific behavior is needed.
- **Maintain consistent spacing** using multiples of 4 or 8.
- **Support both light and dark themes** from the start.
- **Ensure all text is internationalization-ready** using Flutter's localization.

### 📱 Platform-Specific Considerations
- **Test on both iOS and Android** simulators/emulators.
- **Handle platform differences** using `Platform.isIOS` and `Platform.isAndroid`.
- **Request permissions properly** using permission_handler.
- **Handle different screen sizes** with responsive layouts.
- **Use platform-specific icons** and navigation patterns where appropriate.

# Feature Overview

PIPFLOW AI is a cross-platform trading application built with Flutter, migrated from a native iOS Swift/SwiftUI application. The app empowers retail forex and crypto traders by combining:

* **Social trading** – one‑tap copy of vetted expert strategies
* **AI Auto‑Trading** – real‑time analysis and execution via MetaAPI for MT4/MT5 broker connections
* **AI‑Generated Signals & Insights** – natural‑language trade alerts with SL/TP
* **Interactive AI Academy & Community** – lessons, quizzes, and chat
* **Cross-platform support** – iOS and Android from a single codebase

## Project Structure

```
pipflow_flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App widget configuration
│   ├── core/                     # Core functionality
│   │   ├── config/              # App configuration
│   │   ├── constants/           # App constants
│   │   ├── providers/           # Global providers
│   │   ├── router/              # Navigation setup
│   │   ├── theme/               # Theme configuration
│   │   ├── utils/               # Utility functions
│   │   └── widgets/             # Core reusable widgets
│   └── features/                # Feature modules
│       ├── auth/                # Authentication feature
│       ├── trading/             # Trading feature
│       ├── ai_signals/          # AI signals feature
│       ├── social/              # Social trading feature
│       ├── academy/             # Academy feature
│       └── settings/            # Settings feature
├── test/                        # Test files
├── assets/                      # Images, fonts, etc.
├── pubspec.yaml                 # Dependencies
└── README.md                    # Project documentation
```

## Documentation

* Flutter Documentation: [https://docs.flutter.dev/](https://docs.flutter.dev/)
* Riverpod Documentation: [https://riverpod.dev/](https://riverpod.dev/)
* MetaAPI REST API: [https://metaapi.cloud/docs/](https://metaapi.cloud/docs/)
* Supabase Flutter SDK: [https://supabase.com/docs/reference/dart](https://supabase.com/docs/reference/dart)
* Syncfusion Charts: [https://help.syncfusion.com/flutter/charts/overview](https://help.syncfusion.com/flutter/charts/overview)

## Development Guidelines

* Use environment variables (`.env`) for all API keys (MetaAPI, OpenAI, Anthropic, Supabase)
* Enforce code style with `flutter analyze` and `dart format`
* Ensure each feature includes accompanying tests
* Run `flutter test` before committing
* Test on iOS simulator before marking features complete
* Follow the migration plan phases sequentially
* Update MIGRATION_PLAN.md after each phase completion

## Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d iPhone

# Run tests
flutter test

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Format code
dart format lib test

# Clean and get dependencies
flutter clean && flutter pub get
```

do not assume implementations, always fetch official docs from official sites as of august 2025

*Always run build on the simulator once development is done and you want me to check the work and test.d test.

- please make sure to fetch from official flutter docs upon any error you encounter it might help to know were we are going wrong