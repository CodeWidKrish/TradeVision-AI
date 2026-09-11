import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GanttPhase {
  final String title;
  final String timeRange;
  final double startPercent; // 0.0 to 1.0
  final double endPercent;   // 0.0 to 1.0
  final Color color;
  final String patternType;
  final String confidenceScore;
  final String volumeRatio;
  final String keyRange;

  const GanttPhase({
    required this.title,
    required this.timeRange,
    required this.startPercent,
    required this.endPercent,
    required this.color,
    required this.patternType,
    required this.confidenceScore,
    required this.volumeRatio,
    required this.keyRange,
  });
}

class MarketGanttChartWidget extends StatefulWidget {
  final String stockTicker;

  const MarketGanttChartWidget({
    super.key,
    required this.stockTicker,
  });

  @override
  State<MarketGanttChartWidget> createState() => _MarketGanttChartWidgetState();
}

class _MarketGanttChartWidgetState extends State<MarketGanttChartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _progressTimer;
  double _nowProgress = 0.58; // Current session time position (0.0 to 1.0)
  GanttPhase? _selectedPhase;

  final List<GanttPhase> _phases = const [
    GanttPhase(
      title: 'Morning Breakout',
      timeRange: '09:15 - 10:30',
      startPercent: 0.0,
      endPercent: 0.22,
      color: Color(0xFF00C853),
      patternType: 'Opening Bell Bullish Surge',
      confidenceScore: '92%',
      volumeRatio: '2.4x Avg Volume',
      keyRange: '₹2,850 - ₹2,885',
    ),
    GanttPhase(
      title: 'Flag Consolidation',
      timeRange: '10:30 - 12:45',
      startPercent: 0.22,
      endPercent: 0.55,
      color: Color(0xFFFFB300),
      patternType: 'Symmetrical Triangle / Flag',
      confidenceScore: '86%',
      volumeRatio: '0.9x Avg Volume',
      keyRange: '₹2,875 - ₹2,892',
    ),
    GanttPhase(
      title: 'VWAP Accumulation',
      timeRange: '12:45 - 14:15',
      startPercent: 0.55,
      endPercent: 0.78,
      color: Color(0xFF0066CC),
      patternType: 'Institutional Order Sweep',
      confidenceScore: '89%',
      volumeRatio: '1.8x Avg Volume',
      keyRange: '₹2,888 - ₹2,905',
    ),
    GanttPhase(
      title: 'Closing Liquidation',
      timeRange: '14:15 - 15:30',
      startPercent: 0.78,
      endPercent: 1.0,
      color: Color(0xFFFF3B3B),
      patternType: 'Profit Booking & Settlement',
      confidenceScore: '81%',
      volumeRatio: '1.5x Avg Volume',
      keyRange: '₹2,890 - ₹2,902',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _nowProgress += 0.005;
          if (_nowProgress > 1.0) _nowProgress = 0.0;
        });
      }
    });

    _selectedPhase = _phases[2]; // Default select active phase
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);
    final textColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);
    final mutedText = const Color(0xFF8892A4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intraday Market Gantt Timeline',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Live pattern regimes & session trends (${widget.stockTicker})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gantt Chart Bar Timeline Container
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return Column(
                children: [
                  // Time markers row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('09:15 AM', style: GoogleFonts.robotoMono(fontSize: 10, color: mutedText)),
                      Text('11:00 AM', style: GoogleFonts.robotoMono(fontSize: 10, color: mutedText)),
                      Text('01:00 PM', style: GoogleFonts.robotoMono(fontSize: 10, color: mutedText)),
                      Text('03:30 PM', style: GoogleFonts.robotoMono(fontSize: 10, color: mutedText)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Gantt Bars Stack with "NOW" line
                  SizedBox(
                    height: 38,
                    child: Stack(
                      children: [
                        // Phase Bars
                        Row(
                          children: _phases.map((phase) {
                            final phaseWidth = width * (phase.endPercent - phase.startPercent);
                            final isSelected = _selectedPhase == phase;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedPhase = phase),
                              child: Container(
                                width: phaseWidth,
                                height: 38,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: BoxDecoration(
                                  color: phase.color.withOpacity(isSelected ? 0.85 : 0.40),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: phase.color.withOpacity(isSelected ? 1.0 : 0.60),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  phase.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Moving "NOW" Timeline Indicator
                        Positioned(
                          left: width * _nowProgress,
                          top: 0,
                          bottom: 0,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066CC),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'NOW',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFF0066CC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Detailed Pattern Inspector Card for Selected Phase
          if (_selectedPhase != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2733) : const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPhase!.color.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedPhase!.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedPhase!.title} (${_selectedPhase!.timeRange})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedPhase!.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Confidence: ${_selectedPhase!.confidenceScore}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedPhase!.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pattern: ${_selectedPhase!.patternType}',
                              style: GoogleFonts.inter(fontSize: 11, color: mutedText),
                            ),
                            Text(
                              'Volume: ${_selectedPhase!.volumeRatio}',
                              style: GoogleFonts.robotoMono(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
