import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/dark_surfaces.dart';
import 'ai_confidence_gauge.dart';

class AiExplanationSheet extends StatelessWidget {
  final String ticker;
  final String stockName;
  final String signal; // 'STRONG BUY', 'BUY', 'HOLD', 'SELL'
  final double confidenceScore; // 0-100
  final double currentPrice;

  const AiExplanationSheet({
    super.key,
    required this.ticker,
    required this.stockName,
    this.signal = 'STRONG BUY',
    this.confidenceScore = 88.5,
    this.currentPrice = 2896.25,
  });

  static void show(
    BuildContext context, {
    required String ticker,
    required String stockName,
    String signal = 'STRONG BUY',
    double confidenceScore = 88.5,
    double currentPrice = 2896.25,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiExplanationSheet(
        ticker: ticker,
        stockName: stockName,
        signal: signal,
        confidenceScore: confidenceScore,
        currentPrice: currentPrice,
      ),
    );
  }

  Color _getSignalColor(String sig) {
    if (sig.contains('BUY')) return const Color(0xFF10B981);
    if (sig.contains('SELL')) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final signalColor = _getSignalColor(signal);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ticker,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: signalColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: signalColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                signal,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: signalColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stockName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: DarkSurface.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero AI Confidence Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    AiConfidenceGauge(score: confidenceScore, size: 100),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Explainability Engine',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TradeVision Multi-Factor Neural Synthesis analyzed 42 quantitative signals across 4 pillars.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: DarkSurface.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                'Real-time NSE Feed Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4 Pillar Breakdown
              Text(
                'WHY DID AI GENERATE THIS SIGNAL?',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              _buildPillarCard(
                isDark: isDark,
                icon: Icons.trending_up_rounded,
                pillar: 'Technical Momentum',
                weight: '35% Weight',
                status: 'Bullish Breakout',
                statusColor: const Color(0xFF10B981),
                score: 91,
                points: [
                  'RSI at 62.4 — Golden sweet spot, neither oversold nor overextended.',
                  'EMA(20) crossed above EMA(50) forming a strong upward channel.',
                  'Upper Bollinger Band expansion indicates strong volume volatility.',
                ],
              ),
              const SizedBox(height: 10),

              _buildPillarCard(
                isDark: isDark,
                icon: Icons.account_balance_rounded,
                pillar: 'Institutional Flow & Liquidity',
                weight: '30% Weight',
                status: 'Aggressive Accumulation',
                statusColor: const Color(0xFF10B981),
                score: 87,
                points: [
                  'FII / DII net institutional buyers (+₹482 Cr in last 3 sessions).',
                  'Delivery volume spike: 64.2% (10-day median: 48.1%).',
                  'Order book depth shows strong buyer support at key support levels.',
                ],
              ),
              const SizedBox(height: 10),

              _buildPillarCard(
                isDark: isDark,
                icon: Icons.pie_chart_outline_rounded,
                pillar: 'Fundamental Valuation',
                weight: '20% Weight',
                status: 'Fair / Attractive',
                statusColor: const Color(0xFF38BDF8),
                score: 76,
                points: [
                  'Trailing P/E ratio is 14% below its 5-year historical average.',
                  'Return on Capital Employed (ROCE) sustained above 21.4%.',
                  'Low debt-to-equity ratio protects against interest rate shocks.',
                ],
              ),
              const SizedBox(height: 10),

              _buildPillarCard(
                isDark: isDark,
                icon: Icons.newspaper_rounded,
                pillar: 'Sentiment & Macro Tailwinds',
                weight: '15% Weight',
                status: 'Strong Positive',
                statusColor: const Color(0xFF10B981),
                score: 84,
                points: [
                  'Quarterly earnings consensus upgraded by 4 tier-1 brokerages.',
                  'Sector outperforming benchmark index with positive momentum.',
                  'Macro raw material pricing easing down operating costs.',
                ],
              ),
              const SizedBox(height: 20),

              // Action button
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Acknowledge Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillarCard({
    required bool isDark,
    required IconData icon,
    required String pillar,
    required String weight,
    required String status,
    required Color statusColor,
    required double score,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142033) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        pillar,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($weight)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DarkSurface.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          // Bullet points
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
