### 🔄 Project Awareness & Context
- **Always read `PLANNING.md`** at the start of a new conversation to understand the project's architecture, goals, style, and constraints.
- **Check `TASK.md`** before starting a new task. If the task isn’t listed, add it with a brief description and today's date.
- **Use consistent naming conventions, file structure, and architecture patterns** as described in `PLANNING.md`.
- **Use venv_linux** (the virtual environment) whenever executing Python commands, including for unit tests.

### 🧱 Code Structure & Modularity
- **Never create a file longer than 500 lines of code.** If a file approaches this limit, refactor by splitting it into modules or helper files.
- **Organize code into clearly separated modules**, grouped by feature or responsibility.
  For agents this looks like:
    - `agent.py` - Main agent definition and execution logic 
    - `tools.py` - Tool functions used by the agent 
    - `prompts.py` - System prompts
- **Use clear, consistent imports** (prefer relative imports within packages).
- **Use clear, consistent imports** (prefer relative imports within packages).
- **Use python_dotenv and load_env()** for environment variables.

### 🧪 Testing & Reliability
- **Always create Pytest unit tests for new features** (functions, classes, routes, etc).
- **After updating any logic**, check whether existing unit tests need to be updated. If so, do it.
- **Tests should live in a `/tests` folder** mirroring the main app structure.
  - Include at least:
    - 1 test for expected use
    - 1 edge case
    - 1 failure case

### ✅ Task Completion
- **Mark completed tasks in `TASK.md`** immediately after finishing them.
- Add new sub-tasks or TODOs discovered during development to `TASK.md` under a “Discovered During Work” section.

### 📎 Style & Conventions
- **Use Python** as the primary language.
- **Follow PEP8**, use type hints, and format with `black`.
- **Use `pydantic` for data validation**.
- Use `FastAPI` for APIs and `SQLAlchemy` or `SQLModel` for ORM if applicable.
- Write **docstrings for every function** using the Google style:
  ```python
  def example():
      """
      Brief summary.

      Args:
          param1 (type): Description.

      Returns:
          type: Description.
      """
  ```

### 📚 Documentation & Explainability
- **Update `README.md`** when new features are added, dependencies change, or setup steps are modified.
- **Comment non-obvious code** and ensure everything is understandable to a mid-level developer.
- When writing complex logic, **add an inline `# Reason:` comment** explaining the why, not just the what.

### 🧠 AI Behavior Rules
- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate libraries or functions** – only use known, verified Python packages.
- **Always confirm file paths and module names** exist before referencing them in code or tests.
- **Never delete or overwrite existing code** unless explicitly instructed to or if part of a task from `TASK.md`.


# Feature Overview

PIPFLOW AI is a native iOS trading application built with SwiftUI in Xcode and developed using Claude Code within the Cursor AI editor. The app empowers retail forex and crypto traders by combining:

* **Social trading** – one‑tap copy of vetted expert strategies
* **AI Auto‑Trading** – real‑time analysis and execution via MetaAPI or other possible methos to connect  MT5 account of any broker in our app
* **AI‑Generated Signals & Insights** – natural‑language trade alerts with SL/TP
* **Interactive AI Academy & Community** – lessons, quizzes, and chat

This initial prompt describes the core project scope and intended capabilities for our AI coding assistant to implement end-to-end.

## Examples

* `examples/social_trading_ui.swift`: SwiftUI implementation of one‑tap copy trading interface
* `examples/ai_signal_generation.ts`: GPT-4 natural‑language signal generation snippet
* `examples/metaapi_swift_snippet.swift`: MetaAPI REST integration in Swift
* `examples/testing_example.swift`: Pattern for unit tests using XCTest

## Documentation

* SwiftUI & Apple HIG: [https://developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui)
* Cursor AI & Claude Code: [https://docs.cursor.ai/](https://docs.cursor.ai/)
* MetaAPI REST API: [https://metaapi.cloud/docs/](https://metaapi.cloud/docs/)
* TradingView iOS SDK: [https://www.tradingview.com/mobile-sdk/](https://www.tradingview.com/mobile-sdk/)
* Supabase iOS SDK: [https://supabase.com/docs/reference/ios](https://supabase.com/docs/reference/ios)
* RAG Source (for future use): [https://rag.numidia.example.com](https://rag.numidia.example.com)

## Other Considerations

* Use environment variables (`.env`) for all API keys (MetaAPI, OpenAI, Anthropic)
* Enforce code style with SwiftLint and SwiftFormat
* Ensure each feature includes accompanying unit tests (XCTest)
* Maintain project structure:

  ```
  .
  ├── README.md
  ├── initial.md
  ├── examples/
  ├── Sources/
  └── Tests/
  ```
* Follow Apple Human Interface Guidelines for UI components
* Adopt semantic versioning and include a `CHANGELOG.md`
* Document API rate limits and authentication nuances in code comments

*Always run build on the simulator once we done developing and you want me to check the work and test.
