import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/data/stock_data.dart';
import '../core/providers/chat_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state_widget.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  final Function(StockModel stock)? onSelectStock;

  const AiInsightsScreen({
    super.key,
    this.onSelectStock,
  });

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _selectedMode = 'STANDARD'; // QUICK, STANDARD, DETAILED
  String _marketSummaryText = 'Tracking live NSE/BSE indices and sector breadth...';
  String _marketSummaryTime = '';
  bool _isRefreshingSummary = false;

  // Quick Action Chips (Section 44)
  final List<Map<String, String>> _quickActions = [
    {'label': '⚡ Market Summary', 'query': "Provide today's live market summary and indices overview."},
    {'label': '⚖️ Compare TCS vs INFY', 'query': "Compare TCS and INFY"},
    {'label': '🤖 Explain XGBoost ML', 'query': "Explain how the TradeVision XGBoost ML prediction model works."},
    {'label': '📈 Explain RSI', 'query': "Explain RSI indicator in simple words."},
    {'label': '⚠️ Show Market Risks', 'query': "What are the primary risk factors in today's Indian equity market?"},
    {'label': '📱 Watchlist Guide', 'query': "How do I add stocks to my watchlist and configure alerts?"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMarketSummary();
  }

  Future<void> _fetchMarketSummary() async {
    if (_isRefreshingSummary) return;
    setState(() => _isRefreshingSummary = true);
    try {
      final res = await ApiService.fetchAiMarketSummary(mode: 'QUICK');
      if (res != null && res['reply'] != null && mounted) {
        String reply = res['reply'] as String;
        reply = reply.replaceAll('📊 Market Overview\n', '').trim();
        setState(() {
          _marketSummaryText = reply;
          _marketSummaryTime = res['generated_at'] ?? _nowIST();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isRefreshingSummary = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _nowIST() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final h = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    HapticFeedback.lightImpact();
    _controller.clear();

    ref.read(chatMessagesProvider.notifier).addMessage(
          ChatMessage(text: text, isUser: true, time: _nowIST()),
        );

    setState(() {
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Build recent conversation history for Groq context
      final recentMessages = ref.read(chatMessagesProvider);
      final history = recentMessages.take(6).map((m) => {
        'text': m.text,
        'isUser': m.isUser,
      }).toList();

      // Call live Groq API via backend with response depth mode
      final apiRes = await ApiService.sendAiChatMessage(
        text,
        history: history,
        mode: _selectedMode,
      );
      final responseText = (apiRes != null && apiRes['reply'] != null && (apiRes['reply'] as String).isNotEmpty)
          ? apiRes['reply'] as String
          : _getSimpleResponse(text);

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(text: responseText, isUser: false, time: _nowIST()),
          );
    } catch (e) {
      final responseText = _getSimpleResponse(text);
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              text: responseText,
              isUser: false,
              time: _nowIST(),
            ),
          );
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _getSimpleResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('navigate') || q.contains('navigation') || q.contains('tour') || q.contains('walkthrough') || q.contains('whole app') || q.contains('how to use') || q.contains('guide')) {
      final nameMatch = RegExp(r"(?:my name is|i am|i'm|call me)\s+([A-Za-z]+)", caseSensitive: false).firstMatch(query);
      final userName = nameMatch != null ? nameMatch.group(1)! : '';
      final greeting = userName.isNotEmpty ? 'Hello $userName! ' : 'Hello! ';
      return '$greeting' 'Welcome to **TradeVision AI**! Here is your complete guide to navigate through the entire app:\n\n'
          '📱 **4 Main Bottom Navigation Tabs**:\n'
          '• 🏠 **Home**: Live market dashboard with real-time NIFTY 50, SENSEX, and BANK NIFTY indices, top gainers/losers, and instant AI recommendation badges (BUY, SELL, HOLD).\n'
          '• 📊 **Market**: Search any Indian equity (NSE/BSE), track real-time stock prices, sector heatmaps, and build your custom Watchlist by tapping the heart icon.\n'
          '• 📈 **Analytics**: Interactive candlestick charts powered by Syncfusion, technical indicators (RSI 14, MACD, Bollinger Bands, Moving Averages, VWAP), and structural trendlines.\n'
          '• ✨ **AI Copilot (Here!)**: Ask any market question, compare stocks (e.g., *Compare TCS vs INFY*), adjust your response depth (Quick, Standard, Deep), or upload chart screenshots for AI analysis.\n\n'
          '💡 **Stock Details & Paper Trading**:\n'
          'Tap on any stock to view our calibrated **Universal XGBoost (v2)** ML direction forecast (with UP/DOWN probabilities), XAI feature explanations, and test your trading strategies with our virtual **Paper Trading** simulator!';
    } else if (q.contains('hi') || q.contains('hello') || q.contains('hey') || q.contains('good morning') || q.contains('my name is') || q.contains('who are you') || q.contains('what can you do')) {
      final nameMatch = RegExp(r"(?:my name is|i am|i'm|call me)\s+([A-Za-z]+)", caseSensitive: false).firstMatch(query);
      final userName = nameMatch != null ? nameMatch.group(1)! : '';
      final greeting = userName.isNotEmpty ? 'Hello $userName! ' : 'Hello! ';
      return '$greeting' 'I am your **TradeVision AI Copilot** — your intelligent companion for Indian equity markets, technical analysis, and app navigation.\n\n'
          'Here is what I can do for you:\n'
          '• ⚡ **Live Market Updates**: Instant snapshots of NIFTY, SENSEX, and sector movers.\n'
          '• 🤖 **XGBoost ML Predictions**: High-precision mathematical direction forecasts (97.19% gated accuracy).\n'
          '• 📈 **Technical Analysis**: Breakdowns of RSI, MACD, Moving Averages, and Support/Resistance.\n'
          '• ⚖️ **Stock Comparisons**: Side-by-side analysis (e.g. *Compare TCS vs INFY*).\n'
          '• 📱 **App Navigation**: Complete tour and tips for all features.\n\n'
          'Feel free to ask a stock question, tap one of the quick chips below, or ask me how to navigate the app!';
    } else if (q.contains('report') || q.contains('generate')) {
      return '📱 **How to Generate an AI Stock Report in TradeVision**\n\n'
          '1. Go to the **Market & Search** tab (or tap any stock card).\n'
          '2. Select your desired stock (e.g. RELIANCE, TCS, INFY).\n'
          '3. Tap the **"Generate TradeVision AI Report"** button below the chart.\n'
          '4. The platform compiles an 11-section grounded intelligence report combining live market prices, programmatic indicators, news sentiment, and XGBoost probabilities.';
    } else if (q.contains('watchlist') || q.contains('bookmark') || q.contains('save')) {
      return '📱 **Managing Your Watchlist in TradeVision**\n\n'
          '• **Add to Watchlist**: Tap the heart or bookmark icon on any stock card on the Home or Market screen.\n'
          '• **View Saved Stocks**: Switch between "Trending", "Gainers", and "Watchlist" filters on your Home dashboard.\n'
          '• **Alerts**: Enable price notification alerts from the stock detail screen.';
    } else if (q.contains('ml') || q.contains('xgboost') || q.contains('model') || q.contains('predict')) {
      return '📊 **TradeVision XGBoost ML Engine (v2)**\n\n'
          '• **Universal Training**: Trained across 20 NSE sectors and 1,579 verified test sessions.\n'
          '• **Calibrated Precision**: 97.19% Gated Accuracy (when confidence >= 70%) and 0.9869 ROC-AUC.\n'
          '• **Zero Hallucination**: Predicts deterministic mathematical UP/DOWN probabilities without guessing numbers.';
    } else if (q.contains('rsi')) {
      return '📊 **Understanding RSI (Relative Strength Index)**\n\n'
          'RSI measures the speed and magnitude of recent price momentum on a scale from 0 to 100:\n\n'
          '• **Below 30 (Oversold)**: Selling pressure may be exhausted; potential bounce or accumulation zone.\n'
          '• **Above 70 (Overbought)**: Strong buying momentum; potential consolidation or pullback risk.\n'
          '• **30 to 70 (Neutral)**: Normal trend continuation zone.\n\n'
          '💡 *Pro Tip*: Always verify RSI with moving averages and volume!';
    } else if (q.contains('macd')) {
      return '📈 **Understanding MACD Momentum**\n\n'
          'MACD tracks the relationship between two moving averages:\n\n'
          '• **Bullish Crossover**: MACD line crosses above Signal line (upward momentum building).\n'
          '• **Bearish Crossover**: MACD line crosses below Signal line (downward pressure accelerating).\n'
          '• **Centerline**: Trading above zero indicates overall positive trend bias.';
    } else if (q.contains('reliance') || q.contains('buy')) {
      return '📊 **RELIANCE Technical Overview**\n\n'
          '• **Trend Structure**: Consolidating within established key support and resistance zones.\n'
          '• **RSI (14)**: Positioned in neutral territory.\n'
          '• **Risk Management**: Keep protective stops placed directly below primary swing support.\n\n'
          '⚠️ *Educational Disclaimer: Always manage risk and consult a SEBI-registered advisor before trading.*';
    } else if (q.contains('nifty') || q.contains('market')) {
      return '📊 **NIFTY 50 Market Snapshot**\n\n'
          '• **Market Pulse**: Tracking live NSE trading session.\n'
          '• **Key Sectors**: Banking, Auto, and IT provide structural market direction.\n'
          '• **Volatility**: India VIX provides sentiment cues—lower VIX indicates institutional stability.';
    } else {
      return 'TradeVision AI is ready to assist you!\n\n'
          '• Ask for stock analysis (e.g. *Should I buy RELIANCE?*)\n'
          '• Ask about technical indicators (e.g. *What is RSI or MACD?*)\n'
          '• Ask for app help (e.g. *How to generate an AI report?*)\n\n'
          'What would you like to explore today?';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar (Section 48 UI & Section 36 Mode Toggle) ───────
            // ── Top app bar: Branding + Online Pill + Actions ───
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066CC), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'TradeVision AI',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Section 48: Online / Analyzing Indicator Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_isTyping ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (_isTyping ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: _isTyping ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isTyping ? 'Analyzing' : 'Online',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: _isTyping ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Groq AI & Universal XGBoost (v2)',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF8892A4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF8892A4)),
                    tooltip: 'Clear chat',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref.read(chatMessagesProvider.notifier).clearChat();
                    },
                  ),
                ],
              ),
            ),

            // ── Section 36: Dedicated Response Depth Selector Bar ─
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D121F) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 12, color: Color(0xFF8892A4)),
                      const SizedBox(width: 5),
                      Text(
                        'RESPONSE DEPTH',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFF8892A4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModePill('QUICK', 'Quick', isDark),
                        _buildModePill('STANDARD', 'Standard', isDark),
                        _buildModePill('DETAILED', 'Deep', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── PINNED: Dynamic AI Market Summary (Section 27 & 45) ────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? null : const Color(0xFFEFF6FF),
                gradient: isDark
                    ? LinearGradient(colors: [
                        const Color(0xFF0066CC).withValues(alpha: 0.12),
                        const Color(0xFF0A0E1A),
                      ], begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0066CC).withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LIVE AI MARKET SUMMARY',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0066CC),
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (_marketSummaryTime.isNotEmpty)
                              Text(
                                _marketSummaryTime,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  color: const Color(0xFF8892A4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _marketSummaryText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFFCDD5E0) : const Color(0xFF1A1A2E),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Section 45: Live Refresh Button
                  IconButton(
                    icon: _isRefreshingSummary
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0066CC)),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0066CC)),
                    tooltip: 'Refresh AI Analysis',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _isRefreshingSummary ? null : _fetchMarketSummary,
                  ),
                ],
              ),
            ),

            // ── Chat messages list ─────────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.auto_awesome_rounded,
                      title: 'TradeVision AI Copilot',
                      subtitle:
                          'Ask about stocks, technical charts, ML signals, financial news, or TradeVision features.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == messages.length) {
                          return _buildTypingIndicator(isDark);
                        }
                        return _buildChatBubble(messages[index], isDark);
                      },
                    ),
            ),

            // ── Section 44: AI Quick Actions Bar ───────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = _quickActions[index];
                  return ActionChip(
                    label: Text(
                      action['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF0066CC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    backgroundColor: isDark
                        ? const Color(0xFF0066CC).withValues(alpha: 0.12)
                        : const Color(0xFFEFF6FF),
                    side: BorderSide(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: _isTyping ? null : () => _sendMessage(action['query']!),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // ── Input area ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                        ),
                        onSubmitted: _sendMessage,
                        decoration: InputDecoration(
                          hintText: 'Ask about stocks, markets, charts, news or TradeVision...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8892A4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          fillColor: isDark ? const Color(0xFF111827) : Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isTyping ? null : () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isTyping ? const Color(0xFF8892A4) : const Color(0xFF0066CC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTyping ? Icons.hourglass_top_rounded : Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String modeKey, String label, bool isDark) {
    final isSelected = _selectedMode == modeKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMode = modeKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0066CC)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TradeVision AI is typing...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8892A4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth > 800 ? 660.0 : (screenWidth * 0.86).clamp(280.0, 560.0);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? const Color(0xFF0066CC)
              : (isDark ? const Color(0xFF111827) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
          border: msg.isUser
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                ),
          boxShadow: [
            if (!msg.isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header Tag with Copy action on assistant messages
            if (!msg.isUser) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: Color(0xFF0066CC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TradeVision Copilot',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0066CC),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied insight to clipboard',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1E2733),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF8892A4)),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF8892A4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Content body: Formatted Rich Markdown (Zero raw asterisks)
            if (msg.isUser)
              Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.45,
                ),
              )
            else
              _buildFormattedAiText(msg.text, isDark),

            const SizedBox(height: 6),

            // Timestamp footer
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                msg.time,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: msg.isUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF8892A4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parses AI response text into structured blocks: section titles, bullet rows,
  /// bold metrics, and disclaimers without displaying literal asterisk markdown characters.
  Widget _buildFormattedAiText(String text, bool isDark) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final boldColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    const accentColor = Color(0xFF0066CC);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1. Detect Disclaimer or Warning note (often enclosed in * or starting with Disclaimer/Note)
      final cleanLine = line.replaceAll(RegExp(r'^\*+|\*+$'), '').trim();
      final isDisclaimer = cleanLine.toLowerCase().startsWith('disclaimer') ||
          cleanLine.toLowerCase().startsWith('educational disclaimer') ||
          cleanLine.toLowerCase().contains('for educational purposes only');

      if (isDisclaimer) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: mutedColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanLine,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: mutedColor,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 2. Detect Section Headers (lines with #, ##, ###, emojis or bold titles)
      final hashMatch = RegExp(r'^#{1,6}\s*(.*)$').firstMatch(line);
      final isEmojiHeader = line.startsWith('📊') ||
          line.startsWith('📈') ||
          line.startsWith('🎯') ||
          line.startsWith('⚠️') ||
          line.startsWith('📱') ||
          line.startsWith('💡') ||
          line.startsWith('🤖') ||
          line.startsWith('⚖️') ||
          line.startsWith('⚡') ||
          line.startsWith('💼') ||
          line.startsWith('🔍') ||
          (line.startsWith('**') && line.endsWith('**') && line.length < 60);

      if (hashMatch != null || isEmojiHeader) {
        String titleText = hashMatch != null ? hashMatch.group(1)! : line;
        titleText = titleText.replaceAll('**', '').trim();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i > 0 ? 12 : 2, bottom: 6),
            child: Text(
              titleText,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: boldColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
        );
        continue;
      }

      // 3. Detect Markdown Table Separator (e.g. |:---|:---|:---| or |---|---|)
      if (RegExp(r'^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$').hasMatch(line)) {
        continue; // Suppress raw ASCII table divider
      }

      // 4. Detect Markdown Table Rows (e.g. | Indicator | Status | Interpretation |)
      if (line.startsWith('|') && line.endsWith('|') && line.contains('|')) {
        final cells = line
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        if (cells.isNotEmpty) {
          final isTableHeader = cells.any((c) =>
              c.toLowerCase() == 'indicator' ||
              c.toLowerCase() == 'status/value' ||
              c.toLowerCase() == 'interpretation' ||
              c.toLowerCase() == 'parameter' ||
              c.toLowerCase() == 'metric' ||
              c.toLowerCase() == 'stock');

          if (isTableHeader) {
            widgets.add(
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: cells.map((cell) => Expanded(
                    child: Text(
                      cell.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: accentColor,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            );
          } else {
            widgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.35)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cells.map((cell) => Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _parseInlineMarkdown(cell, textColor, boldColor),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            );
          }
          continue;
        }
      }

      // 3. Detect Bullet points (starts with '•', '*', '-', or '1.', '2.')
      final bulletMatch = RegExp(r'^([•\*\-]|(?:\d+\.))\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final bulletSymbol = bulletMatch.group(1)!;
        final content = bulletMatch.group(2)!;
        final isNumbered = RegExp(r'^\d+\.').hasMatch(bulletSymbol);

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: isNumbered
                      ? Text(
                          bulletSymbol,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        )
                      : Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineMarkdown(content, textColor, boldColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 4. Regular Paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(
            text: TextSpan(
              children: _parseInlineMarkdown(line, textColor, boldColor),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses inline string to replace **bold** with bold TextSpans and strip raw asterisks.
  List<TextSpan> _parseInlineMarkdown(
    String raw,
    Color textColor,
    Color boldColor,
  ) {
    final spans = <TextSpan>[];
    // Clean any stray standalone asterisk characters
    final text = raw.replaceAll(RegExp(r'(^|\s)\*(\s|$)'), ' ');

    final baseStyle = GoogleFonts.inter(
      fontSize: 13,
      color: textColor,
      height: 1.5,
    );
    final boldStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: boldColor,
      height: 1.5,
    );

    // Match **bold text**
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      final boldContent = match.group(1) ?? '';
      spans.add(TextSpan(
        text: boldContent,
        style: boldStyle,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
