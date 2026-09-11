import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/data/stock_data.dart';
import '../core/providers/chat_provider.dart';
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

  // Starter prompt chips — beginner friendly
  final List<String> _starters = [
    'Should I buy RELIANCE today?',
    'What is RSI in simple words?',
    'Is NIFTY 50 going up today?',
    'Explain MACD for a beginner',
    'Which sector is performing best?',
    'What does BUY signal mean?',
  ];

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
      // Simulate AI response
      await Future.delayed(const Duration(milliseconds: 1800));

      final response = _getSimpleResponse(text);

      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(text: response, isUser: false, time: _nowIST()),
          );
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(
              text: 'Sorry, I ran into an error processing your query. Please try again.',
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
    if (q.contains('rsi')) {
      return 'RSI (Relative Strength Index) is a simple score from 0 to 100 that tells you if a stock is being bought too much or sold too much.\n\nBelow 30 = Stock may be oversold, could be a good time to buy\nAbove 70 = Stock may be overbought, could be risky to buy now\n30 to 70 = Normal zone\n\nThink of RSI like a temperature gauge for a stock!';
    } else if (q.contains('macd')) {
      return 'MACD helps you understand if a stock\'s momentum is increasing or decreasing.\n\nWhen the MACD line crosses above the signal line = Bullish signal (possible upward move)\nWhen it crosses below = Bearish signal (possible downward move)\n\nIn simple words, MACD tells you if the stock is gaining or losing speed!';
    } else if (q.contains('reliance') || q.contains('buy')) {
      return 'Based on current data, RELIANCE shows strong upward momentum:\n\nRSI: 62.4, Healthy, not overbought\nPattern: Bullish flag formation\nSupport: Rs 2,845\nAI Signal: BUY with 89% confidence\n\nNote: This is educational information only. Always do your own research before investing.';
    } else if (q.contains('nifty') || q.contains('market')) {
      return 'Today\'s NIFTY 50 snapshot:\n\nCurrent: 24,613 (+0.73%)\nTrend: Bullish, Banking & Auto sectors leading\nFII buying: +Rs 1,420 Cr net today\nIndia VIX: 13.2 (Low volatility, good sign)\n\nOverall market mood: Positive for today\'s session!';
    } else if (q.contains('beginner') || q.contains('start') || q.contains('learn')) {
      return 'Great question! Here\'s how to start investing as a beginner:\n\n1. Open a Demat + Trading account (Zerodha, Groww)\n2. Start with Index funds or large-cap stocks\n3. Never invest money you cannot afford to lose\n4. Learn 3 things first: RSI, Support/Resistance, and Volume\n5. Use TradeVision AI\'s signals as guidance, not gospel\n\nWant me to explain any of these in more detail?';
    } else if (q.contains('sector') || q.contains('perform')) {
      return 'Current sector performance today:\n\nBanking: +1.2% (Leading)\nAuto: +0.9%\nIT: +0.6%\nPharma: +0.3%\nMetals: -0.4%\nRealty: -0.8%\n\nBanking is the strongest sector today with heavy FII buying. Consider large-cap banking stocks like HDFCBANK and ICICIBANK for exposure.';
    } else if (q.contains('signal')) {
      return 'A BUY signal means our AI has analyzed the stock\'s chart patterns, volume, momentum, and institutional activity and believes the stock price is likely to go up.\n\nConfidence percentage tells you how sure the AI is:\n90%+ = Very strong signal\n70-89% = Good signal\nBelow 70% = Weak signal, be cautious\n\nAlways use signals as one input in your decision, not the only one!';
    } else {
      return 'Great question! Based on current market data, here is what TradeVision AI thinks:\n\nThe market is showing moderate bullish momentum today. NIFTY 50 is up 0.73% with Banking and Auto sectors leading the rally. If you have a specific stock in mind, just ask me about it and I will give you a detailed AI analysis!';
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
            // ── AppBar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Copilot',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Powered by TradeVision Intelligence',
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
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref.read(chatMessagesProvider.notifier).clearChat();
                    },
                  ),
                ],
              ),
            ),

            // ── PINNED: AI Market Summary ──────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? null : const Color(0xFFEFF6FF),
                gradient: isDark
                    ? LinearGradient(colors: [
                        const Color(0xFF0066CC).withValues(alpha: 0.12),
                        const Color(0xFF0A0E1A),
                      ], begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0066CC).withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
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
                        Text(
                          'AI MARKET SUMMARY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0066CC),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Strong Bullish Sentiment -- NIFTY 50 up 0.73%. Banking & Auto leading. FII net buyers at +Rs 1,420 Cr today.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFCDD5E0) : const Color(0xFF1A1A2E),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Chat messages list ─────────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Ask me anything',
                      subtitle:
                          'I can explain stocks, market terms, and give you AI-powered insights in simple language.',
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

            // ── Starter chips (show only when 1 message = just welcome) ──
            if (messages.length == 1)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _starters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chip = _starters[index];
                    return ActionChip(
                      label: Text(
                        chip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF0066CC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: const Color(0xFF0066CC).withValues(alpha: 0.10),
                      side: BorderSide(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _sendMessage(chip),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

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
                          hintText: 'Ask TradeVision AI a question...',
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
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? const Color(0xFF0066CC)
              : (isDark ? const Color(0xFF111827) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                ),
          boxShadow: [
            if (!msg.isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: msg.isUser
                    ? Colors.white
                    : (isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E)),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                msg.time,
                style: GoogleFonts.inter(
                  fontSize: 10,
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
}
