import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MarketDepthWidget extends StatefulWidget {
  final double currentPrice;

  const MarketDepthWidget({
    super.key,
    required this.currentPrice,
  });

  @override
  State<MarketDepthWidget> createState() => _MarketDepthWidgetState();
}

class _MarketDepthWidgetState extends State<MarketDepthWidget> {
  Timer? _tickTimer;
  final Random _random = Random();
  late List<Map<String, dynamic>> _bids;
  late List<Map<String, dynamic>> _asks;
  int? _flashingBidIndex;
  int? _flashingAskIndex;

  @override
  void initState() {
    super.initState();
    _initDepthData();
    _startLiveTicks();
  }

  void _initDepthData() {
    final p = widget.currentPrice;
    _bids = [
      {'price': p - 0.50, 'qty': 1420, 'orders': 18},
      {'price': p - 1.10, 'qty': 2850, 'orders': 34},
      {'price': p - 1.85, 'qty': 4100, 'orders': 52},
      {'price': p - 2.50, 'qty': 6900, 'orders': 89},
      {'price': p - 3.20, 'qty': 11450, 'orders': 140},
    ];

    _asks = [
      {'price': p + 0.55, 'qty': 980, 'orders': 14},
      {'price': p + 1.25, 'qty': 1840, 'orders': 22},
      {'price': p + 1.95, 'qty': 3200, 'orders': 41},
      {'price': p + 2.70, 'qty': 5400, 'orders': 78},
      {'price': p + 3.45, 'qty': 9800, 'orders': 112},
    ];
  }

  void _startLiveTicks() {
    _tickTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      setState(() {
        // Randomly pick 1 bid and 1 ask to flash with updated quantities
        final bidIdx = _random.nextInt(3);
        final askIdx = _random.nextInt(3);

        final bidDelta = (_random.nextInt(160) - 70);
        final askDelta = (_random.nextInt(160) - 70);

        _bids[bidIdx]['qty'] = max(200, (_bids[bidIdx]['qty'] as int) + bidDelta);
        _asks[askIdx]['qty'] = max(200, (_asks[askIdx]['qty'] as int) + askDelta);

        _flashingBidIndex = bidIdx;
        _flashingAskIndex = askIdx;
      });

      // Reset flash highlight after 600ms
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _flashingBidIndex = null;
            _flashingAskIndex = null;
          });
        }
      });
    });
  }

  @override
  void didUpdateWidget(MarketDepthWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.currentPrice - widget.currentPrice).abs() > 0.05) {
      _initDepthData();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalBidQty = _bids.fold<int>(0, (sum, b) => sum + (b['qty'] as int));
    final totalAskQty = _asks.fold<int>(0, (sum, a) => sum + (a['qty'] as int));
    final total = totalBidQty + totalAskQty;
    final buyPercent = total > 0 ? (totalBidQty / total * 100) : 50.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Live Buyers & Sellers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gain.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.gain.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: AppColors.gain),
                        SizedBox(width: 4),
                        Text(
                          'L2 STREAM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gain,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Buyer vs Seller Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buyers: ${buyPercent.toStringAsFixed(1)}% ($totalBidQty Qty)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gain,
                    ),
                  ),
                  Text(
                    'Sellers: ${(100 - buyPercent).toStringAsFixed(1)}% ($totalAskQty Qty)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.loss,
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
                      Expanded(
                        flex: (buyPercent * 10).toInt().clamp(1, 999),
                        child: Container(color: AppColors.gain),
                      ),
                      Expanded(
                        flex: ((100 - buyPercent) * 10).toInt().clamp(1, 999),
                        child: Container(color: AppColors.loss),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Level 2 Table Header
          Row(
            children: [
              // Bids Side Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BUYERS PAYING (BID)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gain)),
                    Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const VerticalDivider(width: 16),
              // Asks Side Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SELLERS ASKING (ASK)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.loss)),
                    Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 12, color: theme.dividerColor),

          // 5 Rows of Bids vs Asks with micro-flash animations
          Column(
            children: List.generate(5, (i) {
              final bid = _bids[i];
              final ask = _asks[i];
              final bidPrice = (bid['price'] as double).toStringAsFixed(2);
              final askPrice = (ask['price'] as double).toStringAsFixed(2);
              final bidQty = bid['qty'].toString();
              final askQty = ask['qty'].toString();

              final isBidFlashing = _flashingBidIndex == i;
              final isAskFlashing = _flashingAskIndex == i;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    // Bid Row with micro-flash
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBidFlashing
                              ? AppColors.gain.withValues(alpha: isDark ? 0.20 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹$bidPrice', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.gain)),
                            Text(bidQty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ask Row with micro-flash
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAskFlashing
                              ? AppColors.loss.withValues(alpha: isDark ? 0.20 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹$askPrice', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.loss)),
                            Text(askQty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
