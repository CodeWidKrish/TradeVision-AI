# 🎓 TradeVision AI — Final Year Diploma Viva & Project Defense Guide

> **Institution:** Department of Computer Engineering, Shri Bhagubhai Mafatlal Polytechnic & College of Engineering, Mumbai  
> **Project Supervisor:** Prof. Prachi Arora — Senior Lecturer  
> **Student Authors:** Krish Hingu, Krishna Bhundiya, Parv Khichadia  
> **Platform Version:** 1.0.0 (Universal XGBoost v2 + Groq Copilot + Syncfusion Japanese Candlesticks)

---

## 📑 Table of Contents
1. [⚡ 2-Minute Elevator Pitch (How to Introduce the Project)](#-2-minute-elevator-pitch)
2. [🏛️ High-Level System Architecture](#%EF%B8%8F-high-level-system-architecture)
3. [🎯 Top 10 Examiner Questions & Model Answers](#-top-10-examiner-questions--model-answers)
4. [📐 Mathematical Formulations & Indicator Logic](#-mathematical-formulations--indicator-logic)
5. [📖 Standard Diploma Black Book / Project Report Index](#-standard-diploma-black-book--project-report-index)
6. [🎬 Step-by-Step Viva Live Demonstration Workflow](#-step-by-step-viva-live-demonstration-workflow)

---

## ⚡ 2-Minute Elevator Pitch
*(Deliver this when the examiner says: "Tell us about your project in brief.")*

> *"Respected Examiners, retail stock market participants in India face a significant challenge: market information is fragmented. Traditional broker platforms display raw price charts in isolation, forcing users to manually correlate technical oscillators, corporate news, and macroeconomic events without actionable risk context.*
> 
> *To solve this, we created **TradeVision AI** — an institutional-grade, cross-platform equity intelligence and simulation ecosystem. It combines:*
> 1. *A **Universal XGBoost v2 Machine Learning Engine** trained on 27 engineered technical features with dual-sigmoid gating, achieving 97.19% directional precision on calibrated signals.*
> 2. *A **Brownian Bridge Stochastic Anchoring Algorithm** that eliminates discrete chart drift at 60 FPS.*
> 3. *An **Explainable AI (XAI)** reasoning waterfall providing mathematical transparency rather than a black-box answer.*
> 4. *A **Sub-Second Groq Copilot** delivering multi-tier technical synthesis.*
> 5. *A **Virtual Paper Trading Sandbox** with ₹10,00,000 in simulated margin for risk-free strategy validation.*
> 
> *Our research on this architecture has been compiled into a formal academic paper supervised by Prof. Prachi Arora."*

---

## 🏛️ High-Level System Architecture

```mermaid
graph TD
    subgraph ClientLayer["🖥️ Frontend (Flutter 3.x Cross-Platform)"]
        UI["Modern UI / OLED Dark Mode"]
        Riverpod["Riverpod State Lifecycle"]
        Charts["Syncfusion Candlesticks & Brownian Bridge"]
        PT_UI["₹10 Lakh Paper Trading Engine"]
    end

    subgraph APILayer["⚡ Asynchronous Backend (FastAPI / Python)"]
        WS["/ws/market (Live WebSocket Stream)"]
        REST["REST API Endpoints (Auth, News, ML, Charts)"]
        AuthService["JWT Security & Bcrypt Hashing"]
    end

    subgraph QuantitativeML["🧠 Quantitative & AI Intelligence Layer"]
        XGB["Universal XGBoost v2 (27 Features)"]
        FinBERT["FinBERT NLP Sentiment Classifier"]
        Groq["Groq LPU Engine (Llama 3 / Qwen)"]
        XAI["XAI Indicator Attribution Waterfall"]
    end

    subgraph DataStorage["💾 Data & Persistence Layer"]
        YF["Yahoo Finance Live NSE/BSE"]
        GoogleRSS["Google News RSS Feeds"]
        DB["SQLite (aiosqlite) / Supabase PostgreSQL"]
    end

    UI --> Riverpod
    Riverpod --> WS
    Riverpod --> REST
    WS --> YF
    REST --> QuantitativeML
    REST --> DB
    QuantitativeML --> DB
```

---

## 🎯 Top 10 Examiner Questions & Model Answers

### Q1: Why did you choose XGBoost instead of an LSTM / Recurrent Neural Network?
**Model Answer:**
> *"Financial time-series data is notoriously non-stationary and exhibits low signal-to-noise ratio. Deep LSTMs frequently overfit on market noise, suffer from vanishing gradients, and incur heavy inference latency on commodity hardware.  
> Gradient Boosted Decision Trees (**XGBoost v2**) excel on structured, tabular technical indicators (such as RSI, MACD histograms, OBV slopes, and volatility bands). Our XGBoost model evaluates 27 engineered features in less than 12 milliseconds of CPU inference latency, making it dramatically faster, lighter, and more interpretable than deep recurrent networks."*

### Q2: What is the Brownian Bridge and why is it needed in stock charting?
**Model Answer:**
> *"When rendering live market ticks between discrete exchange time bars, naive linear interpolation produces robotic straight lines, while pure random walks cause the price to artificially drift away from actual exchange quotes.  
> We implemented the **Brownian Bridge stochastic process**:  
> $$B(t) = W(t) - t W(1), \quad t \in [0, 1]$$  
> where $W(t)$ is a standard Wiener process. The Brownian Bridge forces the trajectory to strictly anchor to the historical open at $t=0$ and the live exchange close at $t=1$, while organically synthesizing realistic intraday micro-volatility at 60 frames per second."*

### Q3: What is Dual-Sigmoid Gating?
**Model Answer:**
> *"Traditional binary classifiers force every market scenario into either a BUY or SELL, which causes catastrophic false positives during choppy, sideways, or range-bound markets.  
> In TradeVision AI, we apply a **Dual-Sigmoid Gating Mechanism**:
> - If $P(\text{Bullish}) \ge 0.65$, emit a **BUY** signal.
> - If $P(\text{Bearish}) \ge 0.65$, emit a **SELL** signal.
> - If neither threshold is crossed, the signal is strictly gated as **HOLD**.  
> This gating is why our out-of-sample directional precision reaches 97.19% on qualified trades."*

### Q4: How does your Explainable AI (XAI) feature work?
**Model Answer:**
> *"External regulators and institutional investors reject black-box models. TradeVision AI computes feature attribution weights across 4 quantitative pillars:
> 1. **Technical Momentum (35% weight):** RSI sweet spot and Moving Average Golden Crosses.
> 2. **Institutional Flow & Liquidity (30% weight):** Delivery volume spikes and Order Book depth.
> 3. **Fundamental Valuation (20% weight):** P/E ratios and ROCE metrics.
> 4. **Sentiment & Macro Factors (15% weight):** FinBERT news polarity.  
> We present this as an interactive visual attribution waterfall in the stock detail sheet."*

### Q5: How is news sentiment extracted and scored?
**Model Answer:**
> *"We aggregate real-time headlines from Indian financial news feeds (Google News RSS, Moneycontrol). The headlines are processed using **FinBERT** (a BERT model pretrained specifically on corporate and financial vocabulary like *EBITDA, contraction, dividend cut, margin expansion*). FinBERT assigns probability logits across three classes: **Positive**, **Neutral**, and **Negative**, yielding a normalized sentiment score between $-1.0$ and $+1.0$."*

### Q6: How does the Paper Trading Simulator work? Is real money involved?
**Model Answer:**
> *"No real money is involved. Users start with **₹10,00,000** in simulated virtual capital. When an order is placed:
> 1. The engine checks available cash margin.
> 2. It fetches the live market ask/bid price and accounts for a 0.05% realistic execution slippage.
> 3. Transactions and open holdings are committed asynchronously into the database.
> 4. Unrealized P&L is updated dynamically on every price tick."*

### Q7: What happens if there is no internet connection or external APIs are blocked?
**Model Answer:**
> *"TradeVision AI is designed with **Graceful Degradation**:
> 1. In `groq_service.py`, if the Groq API key is missing or the network is blocked, the engine automatically routes queries to a built-in deterministic educational fallback synthesizer.
> 2. In the frontend, offline cached quotes and bundled NIFTY 500 equity masters load immediately from local storage and SQLite, ensuring zero red-screen crashes during an offline presentation."*

### Q8: Why did you choose FastAPI over Flask or Django?
**Model Answer:**
> *"FastAPI is built on Starlette and Pydantic, supporting native Python `async`/`await` coroutines and `uvicorn` ASGI. It handles thousands of concurrent WebSocket connections for live stock ticking with minimal memory footprint. Additionally, FastAPI automatically generates interactive Swagger/OpenAPI documentation at `/docs` out of the box."*

### Q9: Why Flutter for the frontend?
**Model Answer:**
> *"Flutter compiles directly to ARM/x64 machine code without a JavaScript bridge (unlike React Native), enabling 60 to 120 FPS hardware-accelerated canvas rendering via Skia/Impeller. This is critical for drawing multi-timeframe candlestick charts and 3D Matrix4 card flip animations without frame drops."*

### Q10: How are passwords and user sessions secured?
**Model Answer:**
> *"Passwords are salted and hashed using the **Bcrypt** cryptographic algorithm (`passlib`). Authentication tokens are issued as cryptographically signed **JSON Web Tokens (JWT)** with HS256 encryption and a 24-hour expiration window."*

---

## 📐 Mathematical Formulations & Indicator Logic

### 1. Relative Strength Index (RSI - 14 Periods)
$$\text{RSI} = 100 - \left( \frac{100}{1 + \text{RS}} \right), \quad \text{where } \text{RS} = \frac{\text{Exponential Moving Average of 14 Gains}}{\text{Exponential Moving Average of 14 Losses}}$$
- $\text{RSI} > 70$: Overbought region (potential bearish mean-reversion).
- $\text{RSI} < 30$: Oversold region (potential bullish bounce).

### 2. Moving Average Convergence Divergence (MACD)
$$\text{MACD Line} = \text{EMA}_{12}(\text{Price}) - \text{EMA}_{26}(\text{Price})$$
$$\text{Signal Line} = \text{EMA}_{9}(\text{MACD Line})$$
$$\text{Histogram} = \text{MACD Line} - \text{Signal Line}$$
- Bullish crossover occurs when the MACD Line crosses above the Signal Line.

### 3. Bollinger Bands (20 Periods, 2 Standard Deviations)
$$\text{Middle Band} = \text{SMA}_{20}(\text{Close})$$
$$\text{Upper Band} = \text{Middle Band} + 2 \cdot \sigma_{20}$$
$$\text{Lower Band} = \text{Middle Band} - 2 \cdot \sigma_{20}$$

### 4. Brownian Bridge Formulation
$$B(t) = W(t) - t W(1), \quad t \in [0, 1]$$
- Boundary conditions: $B(0) = 0$ and $B(1) = 0$.
- Interpolated price at fractional time $t$:
$$P(t) = P_{\text{open}} + t \cdot (P_{\text{close}} - P_{\text{open}}) + \sigma \cdot B(t) + \alpha \sin(2\pi t)$$

---

## 📖 Standard Diploma Black Book / Project Report Index

If your college requires a formal 70–100 page printed project report ("Black Book"), structure it according to this university-approved format:

- **Certificate of Authenticity** (Signed by Guide Prof. Prachi Arora, HOD, and External Examiner)
- **Declaration by Students**
- **Acknowledgment**
- **Abstract** (From `docs/RESEARCH_PAPER.md`)
- **List of Figures & List of Tables**

### Chapter 1: Introduction
- 1.1 Background & Motivation
- 1.2 Problem Statement & Challenges in Retail Stock Intelligence
- 1.3 Project Objectives
- 1.4 Scope of the Project

### Chapter 2: Literature Survey
- 2.1 Study of Existing Systems (Zerodha Kite, TradingView, Groww)
- 2.2 Comparison Table of Existing vs. Proposed System
- 2.3 Review of Academic Research Papers on Machine Learning in Finance

### Chapter 3: System Requirements & Analysis
- 3.1 Hardware Requirements (Development vs. Production)
- 3.2 Software Requirements (Flutter, Python, FastAPI, SQLite)
- 3.3 Functional Requirements (FR) & Non-Functional Requirements (NFR)
- 3.4 Data Flow Diagrams (DFD Level 0, Level 1, Level 2)
- 3.5 Use Case Diagrams & UML Sequence Diagrams

### Chapter 4: Mathematical Modeling & System Design
- 4.1 Technical Analysis Mathematical Models (RSI, MACD, Bollinger Bands, VWAP)
- 4.2 Brownian Bridge Stochastic Anchoring Algorithm
- 4.3 Machine Learning Pipeline (Feature Engineering, XGBoost v2, Dual-Sigmoid Gating)
- 4.4 FinBERT Sentiment Classification Architecture
- 4.5 Database Schema Design (ER Diagram)

### Chapter 5: Implementation Details
- 5.1 Backend Services Implementation (`live_market_service`, `ml_prediction_service`, `groq_service`)
- 5.2 Frontend UI & Riverpod State Architecture
- 5.3 Virtual Paper Trading Simulator Module
- 5.4 PDF Financial Report Generation

### Chapter 6: Testing & Quality Assurance
- 6.1 Testing Methodology (Unit Testing, Integration Testing, System Testing)
- 6.2 Test Cases & Execution Results (Automated Pytest Suite — 11/11 Passed)
- 6.3 Performance & Latency Benchmarks (<12ms ML Inference, 60 FPS Charting)

### Chapter 7: Conclusion & Future Scope
- 7.1 Summary of Contributions
- 7.2 Limitations of the Current Version
- 7.3 Future Enhancements (Algorithmic Broker APIs, Options Chain Greeks, Multi-Asset Crypto)
- **References & Bibliography** (IEEE format)

---

## 🎬 Step-by-Step Viva Live Demonstration Workflow

Follow this 5-minute script during your external examiner viva:

1. **Step 1: Launch via `start_presentation.bat`**
   - Double-click `start_presentation.bat`. Show the examiner the clean terminal startup with FastAPI binding to `127.0.0.1:8000`.
2. **Step 2: Home Screen & Market Dashboard**
   - Point out the **Live IST Market Clock** displaying the current market session phase (Pre-Open, Regular, or Post-Market).
   - Show the NIFTY 50 and SENSEX real-time cards with tick flash micro-interactions (green for uptick, red for downtick).
3. **Step 3: Interactive Candlestick Charts**
   - Navigate to the **Analytics** tab. Select a major equity (e.g. `RELIANCE` or `TCS`).
   - Toggle **`MA(20)`**, **`EMA(50)`**, and **`Bollinger Bands`**.
   - Explain the **Brownian Bridge** algorithm smoothing the candlestick transitions without artificial drift.
4. **Step 4: Machine Learning Direction & XAI Waterfall**
   - Tap on the AI Recommendation badge (`BUY / HOLD / SELL`).
   - Show the **Dual-Sigmoid probability score** and the **4-Pillar XAI Waterfall** breakdown.
5. **Step 5: Groq AI Copilot**
   - Open the **Copilot** tab. Ask: *"What is the outlook for TCS?"* or tap the *"Compare TCS vs INFY"* prompt chip.
   - Show the sub-second response speed powered by Groq LPU.
6. **Step 6: Paper Trading Simulator**
   - Navigate to **Paper Trading**. Demonstrate placing a Market Buy order for 10 shares of a stock.
   - Show the instant margin deduction from the ₹10,00,000 sandbox and live P&L tracking.
7. **Step 7: PDF Export & Research Paper**
   - Tap the **Export PDF Report** button to showcase client-side institutional report compilation.
   - Show the examiner your co-authored research paper reference in [docs/RESEARCH_PAPER.md](file:///c:/Users/KRISHNA/Desktop/project1/docs/RESEARCH_PAPER.md).
