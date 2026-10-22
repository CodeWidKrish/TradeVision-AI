# 📄 TradeVision AI — Research Paper

## TradeVision AI: A Multi-Modal Neuro-Stochastic Framework for Real-Time Equity Intelligence Using Brownian Bridge Dynamics and Single-Pass LLM Reasoning

---

### 📥 Download the Full Paper

> **[📄 Click here to view / download the Research Paper (PDF)](https://drive.google.com/file/d/1KdwKMlel6MtoTNJAoMLAERjeIQSsTJVs/view?usp=sharing)**

---

### 👥 Authors

| # | Author | Affiliation | Email |
|---|--------|-------------|-------|
| 1 | **Krish Hingu** | Department of Computer Engineering, Shri Bhagubhai Mafatlal Polytechnic and College of Engineering, Mumbai | krish.hingu064@svkmmumbai.onmicrosoft.com |
| 2 | **Krishna Bhundiya** | Department of Computer Engineering, Shri Bhagubhai Mafatlal Polytechnic and College of Engineering, Mumbai | krishna.bhundiya051@svkmmumbai.onmicrosoft.com |
| 3 | **Parv Khichadia** | Department of Computer Engineering, Shri Bhagubhai Mafatlal Polytechnic and College of Engineering, Mumbai | parv.khichadiya012@svkmmumbai.onmicrosoft.com |

**Project Supervisor:** Prof. Prachi Arora — Senior Lecturer, Department of Computer Engineering, SBMP & CoE, Mumbai (prachi.arora@sbmp.ac.in)

---

### 📝 Abstract

Every trading day retail traders are dealing with the hodgepodge of data on equity exchanges in India (NSE & BSE). Traditional broker apps separate candlesticks from the streams of real news, so that users are required to make manual connections between technical oscillators and news and corporate developments moving at a lightning pace. The non-linear patterns in prices can be learned by deep neural networks, but the weights of those networks are hard to explain, and require a whole lot of compute that mobile chips aren't capable of.

We introduce **TradeVision AI**, an end-to-end solution where we combine server-side momentum calculations with the FinBERT sentiment scoring of news with single-pass reasoning using a language model within a mobile Flutter app. To eliminate synthetic chart drift at the discrete market bars, we are creating a stochastic anchoring algorithm for rendering between market bars, directly linking the sub-minute render trajectories to the live exchange quotes (**Brownian Bridge stochastic anchoring algorithm**, B(t) = W(t) − tW(1) with dual-harmonic wave adjustments).

Our FastAPI back end serializes technical metrics and sentiment polarity into a validated JSON schema. This structured payload is analysed by a hosted LLM during one forward inference pass, with the results including calls to **BUY**, **HOLD** and **SELL**, as well as a calibrated confidence level (50%–95%) and a plain language technical explanation.

Across **252 market sessions** on benchmark Indian equities, TradeVision AI attained a **5-day directional accuracy of 67.8%** and a **Macro F1-score of 0.69**, exceeding baseline models by **+9.1%** while sustaining **59.8 FPS** mobile charting.

---

### 🔑 Keywords

`Stock market forecasting` · `Explainable AI (XAI)` · `Large Language Models` · `FinBERT` · `Brownian Bridge` · `Technical Indicators` · `Flutter` · `FastAPI` · `Mobile Computing`

---

### 🏗️ Tech Stack Used

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Dart) — Cross-platform mobile & web |
| **Backend** | FastAPI (Python) — REST + WebSocket |
| **AI/ML** | Groq LLM, FinBERT, XGBoost, Calibrated ML Pipeline |
| **Data Sources** | Yahoo Finance, Google News RSS, NSE/BSE Live Feeds |
| **Database** | Supabase (PostgreSQL) |
| **Charting** | Brownian Bridge Stochastic Anchoring Algorithm |

---

### 📊 Key Results

| Metric | Value |
|--------|-------|
| 5-Day Directional Accuracy | **67.8%** |
| Macro F1-Score | **0.69** |
| Improvement over Baselines | **+9.1%** |
| Mobile Charting FPS | **59.8 FPS** |
| Market Sessions Tested | **252** |

---

### 📂 Repository Structure

```
TradeVision/
├── project/
│   ├── backend/          # FastAPI backend (Python)
│   ├── frontend/         # Flutter frontend (Dart)
│   ├── docs/             # Documentation & Research Paper
│   │   └── RESEARCH_PAPER.md   ← You are here
│   └── README.md         # Project README
```

---

> **© 2026 Krish Hingu, Krishna Bhundiya, Parv Khichadia — All Rights Reserved.**
