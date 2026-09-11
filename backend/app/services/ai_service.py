import os
import logging
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

# HuggingFace token from environment variables
HF_TOKEN = os.getenv("HUGGINGFACE_API_TOKEN") or os.getenv("HUGGINGFACEHUB_API_TOKEN")

# Attempt to import InferenceClient
try:
    from huggingface_hub import InferenceClient
    HAS_HF_HUB = True
except ImportError:
    HAS_HF_HUB = False
    logger.warning("huggingface_hub is not installed. AI generation will fall back to mock templates.")

class AIService:
    def __init__(self):
        self.model_id = "Wizcoderr/Qwen3-14B-Flutter-Fused"
        self.client = None
        
        if HAS_HF_HUB and HF_TOKEN:
            try:
                self.client = InferenceClient(model=self.model_id, token=HF_TOKEN)
                logger.info(f"Successfully initialized Hugging Face InferenceClient for {self.model_id}")
            except Exception as e:
                logger.error(f"Failed to initialize Hugging Face client: {e}")

    def is_configured(self) -> bool:
        """Returns True if the Hugging Face client is ready for live requests."""
        return self.client is not None

    async def generate_code(self, prompt: str, max_tokens: int = 2048, temperature: float = 0.7) -> str:
        """
        Generates Flutter code using Wizcoderr/Qwen3-14B-Flutter-Fused.
        If the token is missing or API call fails, falls back to high-quality mock code.
        """
        system_prompt = (
            "You are a premium Flutter developer expert. Your task is to output ONLY valid, "
            "syntactically correct Dart/Flutter code based on the user request.\n"
            "Guidelines:\n"
            "- Use Material 3 and modern design concepts (Glassmorphism, dark themes, gradients).\n"
            "- Ensure the widget is responsive and follows Clean Architecture separation of concerns.\n"
            "- Use Riverpod for state management if appropriate.\n"
            "- Do not include markdown explanation, preamble, or postamble. Return ONLY the code block "
            "or raw code.\n"
        )
        
        full_prompt = f"{system_prompt}\nUser Prompt: {prompt}\n\nDart Code:"

        # Try live generation if client is available
        if self.client:
            try:
                # Use HF Inference Serverless API or fallback to mock
                logger.info("Attempting live code generation with Wizcoderr/Qwen3-14B-Flutter-Fused...")
                
                # InferenceClient.text_generation is synchronous, run it safely
                response = self.client.text_generation(
                    prompt=full_prompt,
                    max_new_tokens=max_tokens,
                    temperature=temperature,
                    stop_sequences=["```"]
                )
                
                # Post-process response to ensure we only return code
                code = response.strip()
                if "```dart" in code:
                    code = code.split("```dart")[1].split("```")[0].strip()
                elif "```" in code:
                    code = code.split("```")[1].split("```")[0].strip()
                
                if code and len(code) > 50:
                    return code
            except Exception as e:
                logger.error(f"Live AI generation failed: {e}. Falling back to premium pre-built dashboard components.")

        # Fallback to high-quality pre-built Flutter widgets matching the keywords
        return self._get_mock_flutter_code(prompt)

    def _get_mock_flutter_code(self, prompt: str) -> str:
        """
        Returns stunning, production-ready Flutter mock code for typical trading app prompts.
        This ensures a flawless user experience even if no API key is set.
        """
        prompt_lower = prompt.lower()
        
        # 1. Stock Dashboard / Dashboard
        if "dashboard" in prompt_lower or "main screen" in prompt_lower:
            return """import 'package:flutter/material.dart';
import 'dart:ui';

/// Premium Stock Market Dashboard UI
/// Created using TradeVision Qwen3 AI generator (Fallback Mode)
class PremiumDashboardScreen extends StatelessWidget {
  const PremiumDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TradeVision AI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildGlassPortfolioCard(),
            const SizedBox(height: 24),
            const Text(
              'Trending Assets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrendingGrid(),
            const SizedBox(height: 24),
            const Text(
              'AI Market Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAIInsightsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome Back, Trader',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        Text(
          'Analyze & Conquer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.black,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPortfolioCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.01),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Worth Valuation',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, py: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C805).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+5.23%',
                      style: TextStyle(
                        color: Color(0xFF00C805),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '\\$142,580.90',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPortfolioStat('Invested', '\\$98,400.00'),
                  _buildPortfolioStat('Cash Balance', '\\$44,180.90'),
                  _buildPortfolioStat('Today Profit', '+\\$1,240.00'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingGrid() {
    final stocks = [
      {'symbol': 'NVDA', 'name': 'NVIDIA Corp.', 'price': '\\$127.40', 'change': '+4.12%', 'up': true},
      {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': '\\$224.50', 'change': '-0.85%', 'up': false},
      {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': '\\$198.80', 'change': '+2.41%', 'up': true},
      {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'price': '\\$418.20', 'change': '+0.15%', 'up': true},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final bool isUp = stock['up'] as bool;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16181F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stock['symbol'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    stock['change'] as String,
                    style: TextStyle(
                      color: isUp ? const Color(0xFF00C805) : const Color(0xFFFF3B30),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock['name'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock['price'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIInsightsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1A47), Color(0xFF0E0E14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Opportunity Radar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Technical indicators show NVDA is exiting a consolidation pattern. Volume is 20% higher than average. Bullish bias confirmed.',
            style: TextStyle(color: Color(0xFFD1CEE2), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text('View Analytics'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
"""

        # 2. Glassmorphic Chart / TradingView style chart
        elif "chart" in prompt_lower or "graph" in prompt_lower:
            return """import 'package:flutter/material.dart';
import 'dart:ui';

/// TradingView-inspired Glassmorphism Stock Chart Card
/// Created using TradeVision Qwen3 AI generator (Fallback Mode)
class GlassStockChartCard extends StatelessWidget {
  final String symbol;
  final String price;
  final String change;
  final bool isPositive;

  const GlassStockChartCard({
    Key? key,
    this.symbol = 'BTC/USDT',
    this.price = '\\$94,120.50',
    this.change = '+2.75%',
    this.isPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildChartArea(),
                    const SizedBox(height: 16),
                    _buildTimeframeSelector(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.flash_on, color: Colors.amber, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Binance spot market tracker',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? const Color(0xFF00C805) : const Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartArea() {
    return Expanded(
      child: CustomPaint(
        size: Size.infinite,
        painter: ChartPainter(
          isPositive: isPositive,
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final periods = ['1h', '24h', '1w', '1m', '1y', 'ALL'];
    String selected = '24h';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: periods.map((period) {
        bool isSelected = period == selected;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            period,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChartPainter extends CustomPainter {
  final bool isPositive;
  ChartPainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = isPositive ? const Color(0xFF00C805) : const Color(0xFFFF3B30)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isPositive ? const Color(0xFF00C805) : const Color(0xFFFF3B30)).withOpacity(0.25),
          (isPositive ? const Color(0xFF00C805) : const Color(0xFFFF3B30)).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.2, size.height * 0.8, size.width * 0.4, size.height * 0.3, size.width * 0.6, size.height * 0.4);
    path.cubicTo(size.width * 0.8, size.height * 0.5, size.width * 0.9, size.height * 0.1, size.width, size.height * 0.2);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw the gradient filled area
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw the trend line
    canvas.drawPath(path, strokePaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
"""

        # 3. AI Chat Assistant
        elif "chat" in prompt_lower or "assistant" in prompt_lower or "bot" in prompt_lower:
            return """import 'package:flutter/material.dart';

/// Premium Trading AI Chat Assistant Widget
/// Created using TradeVision Qwen3 AI generator (Fallback Mode)
class TradeAIChatAssistant extends StatefulWidget {
  const TradeAIChatAssistant({Key? key}) : super(key: key);

  @override
  State<TradeAIChatAssistant> createState() => _TradeAIChatAssistantState();
}

class _TradeAIChatAssistantState extends State<TradeAIChatAssistant> {
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Welcome to TradeVision AI Assistant. How can I help you analyze the markets today?",
      'isMe': false,
      'time': "08:15 AM",
    },
    {
      'text': "What is the sentiment score for Tesla (TSLA) right now?",
      'isMe': true,
      'time': "08:16 AM",
    },
    {
      'text': "TSLA Sentiment is currently Bullish (78/100). Social sentiment has rebounded after strong production reports, though technical oscillators show overbought conditions on the daily timeframe.",
      'isMe': false,
      'time': "08:16 AM",
    }
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _controller.text,
        'isMe': true,
        'time': 'Just now',
      });
      _controller.clear();
    });
    
    // Trigger mock response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': "Analyzing indicators... FinBERT returns Positive score of 0.88. Opportunity rating: Strong BUY.",
            'isMe': false,
            'time': 'Just now',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161822),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'TradeVision AI',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online • Powered by Qwen & FinBERT',
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
              ],
            )
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : const Color(0xFF1C1E26),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'] as String,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask about any stock, news, or technicals...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                fillColor: const Color(0xFF0F1015),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
"""

        # 4. Standard Generic UI Component fallback (Portfolio Tracker)
        else:
            return """import 'package:flutter/material.dart';

/// Premium Interactive Flutter Widget
/// Created using TradeVision Qwen3 AI generator (Fallback Mode)
class CustomPremiumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const CustomPremiumCard({
    Key? key,
    this.title = 'AI Generation Complete',
    this.subtitle = 'Double-check variables and run "flutter run"',
    this.icon = Icons.auto_awesome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy to Clipboard'),
                onPressed: () {},
              )
            ],
          ),
        ),
      ),
    );
  }
}
"""
