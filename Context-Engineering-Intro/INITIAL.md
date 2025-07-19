

**Overview & Vision**

**Pipflow AI** is a native **iOS** trading application built with **SwiftUI** in **Xcode**, leveraging **Claude Code** within the **Cursor AI** code editor for automated development. The app empowers retail forex and crypto traders by combining:

* **Social trading** – one‑tap copy of vetted expert strategies
* **AI analysis & automation** – real‑time signals and auto‑execution by an AI “with 20+ years’ experience”
* **Education & community** – AI‑powered academy and social hub

**Target Users:** Retail traders at all skill levels (Beginner → Pro).

---

## Key Features

1. **One‑Click Copy Trading**

   * Link MT4/MT5 accounts via MetaAPI.
   * Mirror expert trades in sub‑second latency.
   * Verified leaderboard with performance & risk metrics.

2. **AI Auto‑Trading**

   * Claude/GPT‑4 analyzes live TradingView data.
   * Executes trades with TP/SL via MetaAPI, respecting user risk settings.
   * Provides trade rationale in natural language.

3. **AI‑Generated Signals & Insights**

   * Continuous market scanning for forex & crypto.
   * Natural‑language signals with entry, SL, TP.
   * On‑chart annotations in TradingView iOS SDK.

4. **Interactive AI Academy**

   * Structured curriculum (Beginner → Pro) with lessons, quizzes, certifications.
   * AI tutor chatbot for context‑aware Q\&A.
   * Progress tracking via Supabase.

5. **Economic Calendar & AI Commentary**

   * Live macro event calendar.
   * Instant AI analysis and trade suggestions per event.

6. **AI Strategy Builder (EA Generator)**

   * Natural‑language strategy prompts → Claude‑generated MQL5 code.
   * In‑app compile, backtest, and EX5 download.

7. **AI Chart Annotations**

   * AI‑drawn trends, patterns, S/R levels on TradingView charts.
   * Toggleable layers with embedded AI commentary.

8. **Social Community & Gamification**

   * In‑app feed and chat rooms (WebSockets).
   * Badges, contests, and token rewards.

9. **Tokenized Rewards**

   * Earn “NUMI” tokens for activity (lessons, posts, wins).
   * Spend tokens on perks: advanced AI reports, VIP rooms.

10. **Augmented Reality (AR) Market Overlay**

    * Use ARKit to overlay live currency charts and signals on real‑world surfaces via the iPhone camera.
    * Interactive 3D candlestick models and trendlines viewable in AR for immersive analysis.

11. **Voice‑Activated Trading & Queries**

    * Siri integration for signals, trade placement, and account checks via voice.
    * Custom wake word (e.g., “Hey Numi”) for hands‑free interactions.

12. **Personalized AI Avatar & Holographic UI**

    * Customizable AI avatar delivering insights via animated holographic panels.
    * Multiple persona options (veteran pro, strategist, risk manager).

13. **Predictive Analytics & Sentiment Heatmaps**

    * Real‑time social media sentiment (Twitter, Reddit, Telegram) aggregated into heatmaps.
    * AI‑driven predictive models forecasting short‑term volatility and trend reversals with confidence scores.

14. **Collaborative Trading Rooms**

    * Live group sessions with shared screen charting and audio chat.
    * Real‑time polls for trade decisions before copy execution.

15. **Dynamic UI & Theme Adaptation**

    * Theme shifts by market sentiment: green‑blue bullish, red‑orange bearish, grayscale neutral.
    * Time‑of‑day gradients synced to local sunrise/sunset.

16. **Biometric Security & Trade Confirmation**

    * Face ID/Touch ID for login and trade approvals.
    * Optional fingerprint swipe for high‑value trades.

17. **Gamified Learning Journeys & Leaderboards**

    * Tiered learning paths with XP, levels, and progression bars.
    * Hourly public leaderboards for learners, sim traders, mentors.

18. **Virtual Reality (VR) Trading Arena**

    * Apple Vision Pro support: immersive VR trading room with 3D charts and AI coach holograms.
    * Gesture‑based chart manipulation and trade execution.

19. **Strategy Marketplace & NFT‑Powered Assets**

    * In‑app marketplace for tokenized strategy NFTs.
    * Royalties for strategy creators on each use.

20. **Adaptive Portfolio Health & Tax Advisor**

    * AI‑driven portfolio health score evaluating risk, diversification, performance.
    * Integrated tax‑report generator for compliance and optimization suggestions.

21. **Dark Web Threat & Scam Alerts**

    * Monitor trading‑related dark web forums for leaks or scams.
    * Push alerts if credentials or broker data are compromised.

22. **Cross‑Device Continuity & Offline AI**

    * Handoff between iPhone, iPad, and Vision devices with synced state.
    * Core AI features available offline via on‑device ML for signal recaps and portfolio summaries.

---

## Technology & Architecture

**MetaAPI Integration Strategy:**
No native iOS SDK exists for MetaAPI. Consider the following approaches:

* **Direct REST Calls** from Swift using URLSession or Alamofire to call MetaAPI endpoints with Bearer tokens.
* **Generated Swift Client** by feeding the MetaAPI OpenAPI/Swagger spec into `openapi-generator` to produce a typed Swift SDK.
* **Server‑Side Proxy**: Deploy a small backend (Node.js/TypeScript) that uses the official MetaAPI SDK; route app requests through this service to keep credentials off‑device.
* **JavaScript Engine Embedding**: Ship JavaScriptCore or V8 in‑app with the MetaAPI JS SDK—adds complexity and bundle size.
* **Native Wrapper**: Build a Swift package wrapper around the JS SDK via Node‑API (high overhead, least recommended).

**Recommended Approaches:**

1. **Direct REST Calls** for fastest implementation and full control.
2. **Server‑Side Proxy** for enhanced security and centralized error handling.

* **Development Environment:** Xcode + SwiftUI, automated by Claude Code in Cursor AI.
* **Frontend (iOS):** Native SwiftUI app following Apple HIG.
* **Database:** Supabase (PostgreSQL + Auth) via the Supabase iOS SDK.
* **Backend:** Node.js/TypeScript with Express + Socket.io for APIs and real-time events.
* **AI Services:** Anthropic Claude for code generation & EA builder; OpenAI GPT-4 for NLP tasks.
* **Charting:** TradingView iOS SDK or embedded WebView with AI overlays.
* **Notifications:** APNs via Firebase Cloud Messaging.
* **Security & Compliance:** HTTPS/TLS, encrypted Keychain storage, risk disclaimers, privacy policy.

---

## User Experience & Design

* **Futuristic AI Theme:** Dark UI with neon accents and refined animations.
* **Onboarding:** Guided walkthrough, demo account option, MT account linking.
* **Dashboard:** Daily AI market brief, portfolio P/L snapshot, social highlights.
* **AI Assistant:** Floating chat widget for context-aware queries.
* **iOS-Optimized UI:** Tab bar navigation, native controls, haptic feedback.

---

## Success Metrics

* **Adoption & Engagement:** DAU/MAU, MT account link rate.
* **Trading Performance:** AI signal win rate, user P/L improvement.
* **Community Vitality:** Posts, active chats, contest participation.
* **Reliability & Trust:** Uptime %, NPS, support ticket trends.
Documentation

SwiftUI & Apple HIG: https://developer.apple.com/documentation/swiftui

Cursor AI & Claude Code: https://docs.cursor.ai/

MetaAPI REST API: https://metaapi.cloud/docs/

TradingView iOS SDK: https://www.tradingview.com/mobile-sdk/

Supabase iOS SDK: https://supabase.com/docs/reference/ios

RAG Source (for future use): https://rag.numidia.example.com
