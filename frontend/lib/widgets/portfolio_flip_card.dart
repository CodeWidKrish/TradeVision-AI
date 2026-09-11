import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ticker_logo.dart';

class PortfolioFlipCard extends StatefulWidget {
  const PortfolioFlipCard({super.key});

  @override
  State<PortfolioFlipCard> createState() => _PortfolioFlipCardState();
}

class _PortfolioFlipCardState extends State<PortfolioFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  bool _isBalanceHidden = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    HapticFeedback.mediumImpact();

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isFront = !_isFront;
          _controller.reset();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isUnder = angle > (math.pi / 2);

        final Widget face;
        if (!isUnder) {
          face = _isFront ? _buildFrontCard(isDark) : _buildBackCard(isDark);
        } else {
          face = _isFront ? _buildBackCard(isDark) : _buildFrontCard(isDark);
        }

        // Dynamic 3D mid-air lift (scale up to 1.07 as it rotates edge-on)
        final scale = 1.0 + math.sin(angle) * 0.07;
        // Dynamic shading overlay as card angles away from view
        final shadowOpacity = (math.sin(angle) * 0.35).clamp(0.0, 0.35);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0014) // 3D Perspective
          ..scale(scale);

        if (!isUnder) {
          transform.rotateY(angle);
        } else {
          transform.rotateY(angle - math.pi);
        }

        return GestureDetector(
          onTap: _flip,
          behavior: HitTestBehavior.opaque,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Stack(
              children: [
                face,
                // Realistic 3D surface illumination / shading overlay
                if (shadowOpacity > 0.01)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── FRONT CARD ──────────────────────────────────────────────────────────
  Widget _buildFrontCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142033) : null,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF16253D), Color(0xFF0F1A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF0044AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0066CC).withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF0066CC).withValues(alpha: 0.22)
                : const Color(0xFF0044AA).withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066CC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Total Portfolio Value',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF8892A4)
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isBalanceHidden = !_isBalanceHidden;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          _isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 15,
                          color: isDark
                              ? const Color(0xFF8892A4)
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 3D FLIP BUTTON
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0066CC).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0066CC).withValues(alpha: 0.50)
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flip_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF38B2AC) : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Flip Details',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Portfolio value (Privacy masked if active)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isBalanceHidden ? '₹ • • • • • •' : '₹4,81,090',
                key: ValueKey<bool>(_isBalanceHidden),
                style: GoogleFonts.robotoMono(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: _isBalanceHidden ? 2.0 : -0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Change pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00C853).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              '+₹3,210 (+0.67%) today',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00C853),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 7-day sparkline
          SizedBox(
            height: 44,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 456000),
                      FlSpot(1, 451000),
                      FlSpot(2, 463000),
                      FlSpot(3, 469000),
                      FlSpot(4, 465000),
                      FlSpot(5, 476000),
                      FlSpot(6, 481090),
                    ],
                    isCurved: true,
                    color: isDark ? const Color(0xFF00C853) : Colors.white,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF00C853).withValues(alpha: 0.25),
                                const Color(0xFF00C853).withValues(alpha: 0.00),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.00),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 445000,
                maxY: 490000,
              ),
            ),
          ),

          const SizedBox(height: 4),
          Text(
            '7-day portfolio trend',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white.withValues(alpha: isDark ? 0.45 : 0.70),
            ),
          ),

          const SizedBox(height: 14),
          Divider(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.20),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _FrontStat('Invested', _isBalanceHidden ? '₹••••••' : '₹4,10,000',
                  Colors.white.withValues(alpha: 0.70), Colors.white),
              _FrontStat('Returns', _isBalanceHidden ? '₹••••••' : '+₹71,090',
                  Colors.white.withValues(alpha: 0.70),
                  const Color(0xFF00C853)),
              _FrontStat('P&L %', '+17.3%',
                  Colors.white.withValues(alpha: 0.70),
                  const Color(0xFF00C853)),
            ],
          ),
        ],
      ),
    );
  }

  // ── BACK CARD ───────────────────────────────────────────────────────────
  Widget _buildBackCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17253B) : const Color(0xFF004DAA),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF192A44), Color(0xFF111E32)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : const LinearGradient(
                colors: [Color(0xFF0055BB), Color(0xFF003D88)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00C853).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withValues(alpha: 0.20),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Portfolio Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C853).withValues(alpha: 0.50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flip_rounded, size: 13, color: Color(0xFF00C853)),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period performance rows
          const _BackRow('Today\'s Gain', '+₹3,210', '+0.67%', true),
          const _BackRow('Week\'s Gain', '+₹8,420', '+1.78%', true),
          const _BackRow('Month\'s Gain', '+₹21,340', '+4.64%', true),
          const _BackRow('Year\'s Gain', '+₹71,090', '+17.3%', true),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // Visual Allocation Treemap Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asset Allocation',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              Text(
                'Equity 58% • ETF 22% • Debt 12% • Cash 8%',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(flex: 58, child: Container(color: const Color(0xFF38BDF8))),
                  const SizedBox(width: 2),
                  Expanded(flex: 22, child: Container(color: const Color(0xFF00C853))),
                  const SizedBox(width: 2),
                  Expanded(flex: 12, child: Container(color: const Color(0xFFFF8C00))),
                  const SizedBox(width: 2),
                  Expanded(flex: 8, child: Container(color: const Color(0xFF8B5CF6))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // Holdings breakdown
          Text(
            'Top Holdings',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 8),
          const _HoldingBar('RELIANCE', 0.32, Color(0xFF0066CC)),
          const _HoldingBar('HDFCBANK', 0.24, Color(0xFF00C853)),
          const _HoldingBar('TCS', 0.20, Color(0xFFFF8C00)),
          const _HoldingBar('OTHERS', 0.24, Color(0xFF8B5CF6)),

          const SizedBox(height: 12),

          // Risk level
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xFFFF8C00), size: 14),
              const SizedBox(width: 6),
              Text(
                'Risk Level: Medium',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFFF8C00),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Beta: 0.84',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────

class _FrontStat extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  const _FrontStat(this.label, this.value, this.labelColor, this.valueColor);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BackRow extends StatelessWidget {
  final String label;
  final String amount;
  final String percent;
  final bool isPositive;
  const _BackRow(this.label, this.amount, this.percent, this.isPositive);

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              percent,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingBar extends StatelessWidget {
  final String ticker;
  final double percent;
  final Color color;
  const _HoldingBar(this.ticker, this.percent, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ticker == 'OTHERS'
                      ? Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.pie_chart_rounded, size: 10, color: color),
                        )
                      : TickerLogo(
                          ticker: ticker,
                          size: 16,
                          borderRadius: 4,
                        ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticker,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
}
