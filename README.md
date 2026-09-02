<div align="center">

# 📈 TradeVision AI

### *A Stock Market Analysis Tool For Beginners*

Making the Indian stock market (NSE/BSE) approachable — real-time prices, AI-powered signals, and technical indicators explained in plain language, not jargon.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Claude](https://img.shields.io/badge/Claude_AI-8B5CF6?style=for-the-badge&logo=anthropic&logoColor=white)](https://anthropic.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

[Overview](#-overview) •
[Features](#-features) •
[Tech Stack](#%EF%B8%8F-tech-stack) •
[Getting Started](#-getting-started) •
[Architecture](#-architecture) •
[Roadmap](#%EF%B8%8F-roadmap)

</div>

---

## 🎯 Overview

**TradeVision AI** is a cross-platform mobile app built with Flutter that helps first-time investors understand the stock market instead of just staring at numbers. It combines **live market data**, **AI-generated buy/hold/sell signals with plain-English reasoning**, and **beginner-friendly technical indicator explanations** — all wrapped in a clean, TradingView-inspired interface.

> 🎓 Built as a college project / hackathon submission, with production-grade architecture: proper state management, error handling, theming, and a real FastAPI backend — not just a static demo.

---

## ✨ Features

### 🔐 Onboarding & Authentication
- Animated splash screen with live market ticker tape
- 3-step onboarding walkthrough (Market Overview → Technical Indicators → AI Recommendations)
- Secure Login/Signup with real-time validation, rate limiting & lockout protection

### 🏠 Home Dashboard
- Personalized greeting with live IST market clock (auto open/closed detection)
- Portfolio summary card with returns and P&L
- Market Pulse strip (NIFTY 50, SENSEX, BANK NIFTY at a glance)
- Today's Top Movers, Live Watchlist, and curated market news

### 📊 Market & Charts
- **Switchable chart types** — Line 📈 and Candlestick 🕯️ views, just like professional trading terminals
- Multiple timeframes: `1D` `1W` `1M` `3M` `1Y` `MAX`
- Pinch-to-zoom, scroll, and crosshair tooltips with OHLC precision
- RSI gauge & MACD histogram, explained in plain language for beginners

### 💼 Portfolio & Watchlist
- **Holdings screen** — quantity, average price, live P&L per stock
- **Watchlist** — bookmark stocks, live search, persists across sessions
- **Stock Detail** — full OHLC data, AI analysis, technical & company info tabs

### 🤖 AI Copilot
- Chat-based AI assistant powered by the **Claude API**
- Ask questions about any stock and get context-aware, easy-to-understand answers
- AI Signal cards: `BUY` / `HOLD` / `SELL` with a confidence score and a one-line reason

### 📰 Sentiment & News
- Real-time headlines via **NewsAPI**
- Sentiment classification (positive/neutral/negative) via **FinBERT**

### 🎨 Design & Experience
- Full **Dark Mode** 🌙 / **Light Mode** ☀️ with a 5-level elevation system
- Consistent design language: Inter for text, Roboto Mono for all numbers/prices
- Indian currency formatting (₹, lakh/crore notation)
- Haptic feedback, skeleton loaders, and graceful empty/error states everywhere — no crashes, no blank screens

---

## 🛠️ Tech Stack

### Frontend
| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Routing | GoRouter |
| Charts | fl_chart + custom `CustomPainter` candlestick engine |
| Fonts | Google Fonts (Inter, Roboto Mono) |
| Local Storage | SharedPreferences |

### Backend
| Layer | Technology |
|---|---|
| Framework | FastAPI (Python) |
| Market Data | yfinance |
| News | NewsAPI |
| Sentiment Analysis | FinBERT |
| AI Insights & Chat | Claude API (Anthropic) |
| Hosting | Render.com |

### Tooling
| Purpose | Tool |
|---|---|
| AI Pair Programming | Antigravity IDE |
| Version Control | Git & GitHub |

---

## 🏗️ Architecture

```
┌─────────────────────────┐         ┌──────────────────────────┐
│      Flutter Frontend    │ HTTPS   │      FastAPI Backend      │
│  ────────────────────    │◄───────►│  ────────────────────     │
│  • Screens & Widgets      │         │  • REST API Endpoints     │
│  • Riverpod State Layer   │         │  • yfinance (live prices) │
│  • GoRouter Navigation    │         │  • NewsAPI (headlines)    │
│  • Local Cache            │         │  • FinBERT (sentiment)    │
│                            │         │  • Claude API (AI signals)│
└─────────────────────────┘         └──────────────────────────┘
```

---

## 📂 Project Structure

```
TradeVision/
├── frontend/
│   ├── lib/
│   │   ├── screens/          # Splash, Onboarding, Auth, Home, Market,
│   │   │                     # Stock Detail, Holdings, Watchlist,
│   │   │                     # Analytics, AI Copilot, Settings
│   │   ├── widgets/          # Reusable UI components
│   │   ├── models/           # Data models (OhlcPoint, Stock, etc.)
│   │   ├── services/         # API service layer, StorageService
│   │   ├── providers/        # Riverpod state providers
│   │   ├── router/           # GoRouter route definitions
│   │   └── main.dart
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   │   ├── routes/           # API endpoints
│   │   ├── services/         # yfinance, NewsAPI, FinBERT, Claude integrations
│   │   └── main.py
│   └── requirements.txt
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Python 3.10+](https://www.python.org/downloads/)
- API keys for **NewsAPI** and **Claude API**

### 1️⃣ Clone the repository
```bash
git clone https://github.com/KrishnaBhundiya/TradeVision.git
cd TradeVision
```

### 2️⃣ Set up the backend
```bash
cd backend
python -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Create a .env file with your keys
echo "NEWS_API_KEY=your_key_here" >> .env
echo "CLAUDE_API_KEY=your_key_here" >> .env

uvicorn app.main:app --reload
```

### 3️⃣ Set up the frontend
```bash
cd ../frontend
flutter pub get
flutter run -d chrome --web-port 8090
```

The app will connect to your local backend by default — update the base URL in `lib/services/` if your backend is deployed elsewhere.

---

## 🗺️ Roadmap

- [x] Onboarding & Authentication flow
- [x] Home dashboard with live market data
- [x] Dark/Light theme system
- [x] AI Copilot chat interface
- [x] Analytics screen with chart insights
- [x] Switchable Line/Candlestick charts
- [x] Holdings & Stock Detail screens
- [x] Full frontend error handling & exception safety
- [ ] Real-time price streaming (WebSockets)
- [ ] Push notifications for price alerts
- [ ] Multi-language support
- [ ] Paper trading / simulation mode

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👥 Contributors

1. [@KrishnaBhundiya](https://github.com/KrishnaBhundiya)
2. [@CodeWidKrish](https://github.com/CodeWidKrish)
3. [@TechthriveParv](https://github.com/TechthriveParv)

---

<div align="center">

### ⭐ If you find this project useful, consider giving it a star!

*Built with ❤️, Flutter, and a lot of coffee ☕*

</div>
