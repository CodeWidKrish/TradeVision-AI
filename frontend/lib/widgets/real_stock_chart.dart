import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../core/models/ohlc_point.dart' show ChartType;
import '../core/data/stock_data.dart';
import '../services/storage_service.dart';
import 'shimmer_skeleton.dart';

// ── DATA MODEL ───────────────────────────────────────────────────────────
class OHLCData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  OHLCData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;
}

// ── MAIN CHART WIDGET ────────────────────────────────────────────────────
class RealStockChart extends StatefulWidget {
  final String ticker;
  final String period; // 1D, 1W, 1M, 3M, 6M, 1Y
  final ChartType? chartType;
  final ValueChanged<ChartType>? onChartTypeChanged;

  final bool showHeader;
  final EdgeInsetsGeometry? padding;

  const RealStockChart({
    super.key,
    required this.ticker,
    this.period = '1D',
    this.chartType,
    this.onChartTypeChanged,
    this.showHeader = true,
    this.padding,
  });

  @override
  State<RealStockChart> createState() => _RealStockChartState();
}

class _RealStockChartState extends State<RealStockChart> {
  late ChartType _chartType;
  ChartType get _effectiveChartType => widget.chartType ?? _chartType;
  List<OHLCData> _data = [];
  Timer? _liveTimer;
  double _currentPrice = 2891.00;
  double get currentPrice => _currentPrice;
  bool _isPositive = true;
  final Random _random = Random();

  // Technical Indicators Toggles
  bool _showMA20 = true;
  bool _showEMA50 = false;
  bool _showBollinger = false;
  bool _showVolume = true;
  bool _isPanZoomActive = false; // Mobile scroll safety: defaults to off so users can scroll page freely
  bool _isPeriodLoading = false; // Smooth timeframe switch transition

  // Crosshair tracking
  OHLCData? _hoveredCandle;

  @override
  void initState() {
    super.initState();
    final saved = StorageService.getChartType();
    _chartType = widget.chartType ?? (saved == 'line' ? ChartType.line : ChartType.candlestick);
    final stock = StockRepository.getStock(widget.ticker);
    _currentPrice = stock.price;
    _generateRealisticData();
    _startLiveFeed();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  // Generate realistic OHLC data anchored directly to actual stock price
  void _generateRealisticData() {
    final now = DateTime.now();
    _data = [];

    // Always fetch latest reference price and metrics from repository
    final stock = StockRepository.getStock(widget.ticker);
    final targetPrice = stock.price;
    _currentPrice = targetPrice;

    // Period-specific settings
    final config = _getPeriodConfig(widget.period);
    final bars = config['bars'] as int;
    final interval = config['interval'] as Duration;

    final double startPrice;
    final double volatility;

    if (widget.period == '1D') {
      startPrice = stock.openPrice > 0 ? stock.openPrice : (targetPrice - stock.changeAmount);
      volatility = targetPrice * 0.0022;
    } else {
      // Historical period return to give realistic macroeconomic context
      final double periodReturn;
      switch (widget.period) {
        case '1W':
          periodReturn = stock.isPositive ? 0.018 : -0.015;
          break;
        case '1M':
          periodReturn = stock.isPositive ? 0.042 : -0.035;
          break;
        case '3M':
          periodReturn = stock.isPositive ? 0.085 : -0.065;
          break;
        case '6M':
          periodReturn = stock.isPositive ? 0.140 : -0.110;
          break;
        case '1Y':
          periodReturn = stock.isPositive ? 0.240 : -0.180;
          break;
        default: // MAX
          periodReturn = stock.isPositive ? 0.550 : -0.320;
          break;
      }
      startPrice = targetPrice / (1.0 + periodReturn);
      volatility = targetPrice * _getVolatility(widget.period);
    }

    // Brownian Bridge generation: strictly guarantees closes[0] == startPrice
    // and closes[bars] == targetPrice, with realistic organic market fluctuations!
    final closes = List<double>.filled(bars + 1, 0.0);
    closes[0] = startPrice;
    closes[bars] = targetPrice;

    final raw = List<double>.filled(bars + 1, 0.0);
    raw[0] = 0.0;
    for (int i = 1; i <= bars; i++) {
      final step = (_random.nextDouble() - 0.495) * volatility;
      raw[i] = raw[i - 1] + step;
    }

    for (int i = 1; i < bars; i++) {
      final t = i / bars;
      final bridge = raw[i] - t * raw[bars];
      final linear = startPrice + t * (targetPrice - startPrice);
      closes[i] = linear + bridge;
    }

    for (int i = 0; i < bars; i++) {
      final time = now.subtract(interval * (bars - 1 - i));
      final open = closes[i];
      final close = closes[i + 1];

      final wickMult = 0.25 + _random.nextDouble() * 0.35;
      final high = max(open, close) + volatility * wickMult;
      final low = min(open, close) - volatility * wickMult * 0.8;

      final candleSize = (open - close).abs();
      final baseVol = 500000 + _random.nextInt(1500000);
      final vol = baseVol * (1 + candleSize / targetPrice * 10);

      _data.add(OHLCData(
        time: time,
        open: open,
        high: high,
        low: max(low, targetPrice * 0.40),
        close: close,
        volume: vol,
      ));
    }

    _currentPrice = _data.last.close;
    _isPositive = _data.last.close >= _data.first.open;
  }

  Map<String, dynamic> _getPeriodConfig(String period) {
    switch (period) {
      case '1D':
        return {'bars': 78, 'interval': const Duration(minutes: 5)};
      case '1W':
        return {'bars': 42, 'interval': const Duration(hours: 1)};
      case '1M':
        return {'bars': 30, 'interval': const Duration(days: 1)};
      case '3M':
        return {'bars': 90, 'interval': const Duration(days: 1)};
      case '6M':
        return {'bars': 180, 'interval': const Duration(days: 1)};
      case '1Y':
        return {'bars': 52,  'interval': const Duration(days: 7)};
      default: // MAX
        return {'bars': 60,  'interval': const Duration(days: 30)};
    }
  }

  double _getVolatility(String period) {
    switch (period) {
      case '1D':  return 0.0025; // tight — intraday moves
      case '1W':  return 0.0040;
      case '1M':  return 0.0060;
      case '3M':  return 0.0080;
      case '6M':  return 0.0100;
      case '1Y':  return 0.0140;
      default:    return 0.0180; // MAX — widest swings
    }
  }

  // Live tick — new candle every 3 seconds in 1D view
  void _startLiveFeed() {
    if (widget.period != '1D') return;

    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        final last = _data.last;
        final tick = (_random.nextDouble() - 0.48) * last.close * 0.002;
        final newPrice = last.close + tick;
        final newHigh = max(last.high, newPrice);
        final newLow = min(last.low, newPrice);

        // Update last candle (live tick on current candle)
        _data[_data.length - 1] = OHLCData(
          time: last.time,
          open: last.open,
          high: newHigh,
          low: newLow,
          close: newPrice,
          volume: last.volume + _random.nextInt(10000),
        );

        _currentPrice = newPrice;
        _isPositive = _data.last.close >= _data.first.open;
      });
    });
  }

  @override
  void didUpdateWidget(RealStockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartType != null && widget.chartType != oldWidget.chartType) {
      setState(() {
        _chartType = widget.chartType!;
      });
    }
    if (oldWidget.period != widget.period || oldWidget.ticker != widget.ticker) {
      _liveTimer?.cancel();
      final stock = StockRepository.getStock(widget.ticker);
      _currentPrice = stock.price;
      setState(() {
        _isPeriodLoading = true;
      });
      _generateRealisticData();
      _startLiveFeed();
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) {
          setState(() {
            _isPeriodLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartColor = _isPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B3B);

    final hPad = widget.padding != null
        ? 0.0
        : (widget.showHeader ? 16.0 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          // ── Chart type toggle + live indicator ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF00C853).withValues(alpha: 0.30)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: Color(0xFF00C853)),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00C853),
                            letterSpacing: 0.8,
                          )),
                    ],
                  ),
                ),

                const Spacer(),

                // Chart type toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2A3A)
                        : const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _ChartTypeButton(
                        icon: Icons.show_chart_rounded,
                        label: 'Line',
                        isSelected: _effectiveChartType == ChartType.line,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chartType = ChartType.line);
                          StorageService.setChartType(ChartType.line.name);
                          widget.onChartTypeChanged?.call(ChartType.line);
                        },
                      ),
                      const SizedBox(width: 2),
                      _ChartTypeButton(
                        icon: Icons.candlestick_chart_rounded,
                        label: 'Candle',
                        isSelected: _effectiveChartType == ChartType.candlestick,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chartType = ChartType.candlestick);
                          StorageService.setChartType(ChartType.candlestick.name);
                          widget.onChartTypeChanged?.call(ChartType.candlestick);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // ── Technical Indicators Quick-Toggles ──────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _IndicatorChip(
                  label: _isPanZoomActive ? 'Pan: ON' : 'Pan: OFF',
                  icon: _isPanZoomActive ? Icons.pan_tool_rounded : Icons.lock_outline_rounded,
                  color: const Color(0xFF6366F1),
                  isActive: _isPanZoomActive,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isPanZoomActive = !_isPanZoomActive);
                  },
                ),
                const SizedBox(width: 6),
                _IndicatorChip(
                  label: 'MA(20)',
                  color: const Color(0xFFFF8C00),
                  isActive: _showMA20,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showMA20 = !_showMA20);
                  },
                ),
                const SizedBox(width: 6),
                _IndicatorChip(
                  label: 'EMA(50)',
                  color: const Color(0xFF00D2FF),
                  isActive: _showEMA50,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showEMA50 = !_showEMA50);
                  },
                ),
                const SizedBox(width: 6),
                _IndicatorChip(
                  label: 'Bollinger',
                  color: const Color(0xFFC084FC),
                  isActive: _showBollinger,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showBollinger = !_showBollinger);
                  },
                ),
                const SizedBox(width: 6),
                _IndicatorChip(
                  label: 'Volume',
                  color: const Color(0xFF8892A4),
                  isActive: _showVolume,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showVolume = !_showVolume);
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Hovered candle info bar ──────────────────────────────────────
        if (_hoveredCandle != null)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2A3A)
                    : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _OHLCLabel('O',
                    NumberFormat('₹#,##,##0.00', 'en_IN')
                        .format(_hoveredCandle!.open),
                    _hoveredCandle!.isBullish
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B3B),
                  ),
                  const SizedBox(width: 12),
                  _OHLCLabel('H',
                    NumberFormat('₹#,##,##0.00', 'en_IN')
                        .format(_hoveredCandle!.high),
                    const Color(0xFF00C853),
                  ),
                  const SizedBox(width: 12),
                  _OHLCLabel('L',
                    NumberFormat('₹#,##,##0.00', 'en_IN')
                        .format(_hoveredCandle!.low),
                    const Color(0xFFFF3B3B),
                  ),
                  const SizedBox(width: 12),
                  _OHLCLabel('C',
                    NumberFormat('₹#,##,##0.00', 'en_IN')
                        .format(_hoveredCandle!.close),
                    _hoveredCandle!.isBullish
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B3B),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // ── MAIN CHART ───────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: _isPeriodLoading
              ? _buildChartSkeleton(isDark)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey('${widget.ticker}_${widget.period}_${_effectiveChartType}_$_isPanZoomActive'),
                    child: _effectiveChartType == ChartType.candlestick
                        ? _buildCandlestickChart(isDark, chartColor)
                        : _buildLineChart(isDark, chartColor),
                  ),
                ),
        ),

        // ── Volume bars ──────────────────────────────────────────────────
        if (_showVolume)
          SizedBox(
            height: 40,
            child: _buildVolumeChart(isDark),
          ),
      ],
    );
  }

  Widget _buildChartSkeleton(bool isDark) {
    return const ChartSkeleton(height: 220);
  }

  // ── CANDLESTICK CHART ────────────────────────────────────────────────────
  Widget _buildCandlestickChart(bool isDark, Color chartColor) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,

      // Crosshair for professional feel
      crosshairBehavior: CrosshairBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: CrosshairLineType.both,
        lineColor: const Color(0xFF8892A4).withValues(alpha: 0.50),
        lineWidth: 1,
        lineDashArray: const [4, 4],
      ),

      // Trackball — shows OHLC on hover
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        lineColor: const Color(0xFF8892A4).withValues(alpha: 0.60),
        lineWidth: 1,
        lineDashArray: const [4, 4],
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFF1A1A2E),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 10,
            color: Colors.white,
          ),
          borderRadius: 6,
          borderWidth: 1,
          borderColor: const Color(0xFF2A3A50),
        ),
      ),

      // Zoom & pan — controllable via Pan & Zoom toggle
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: _isPanZoomActive,
        enablePanning: _isPanZoomActive,
        enableDoubleTapZooming: _isPanZoomActive,
        enableSelectionZooming: false,
        zoomMode: ZoomMode.x,
      ),

      primaryXAxis: DateTimeAxis(
        dateFormat: widget.period == '1D'
            ? DateFormat('HH:mm')
            : DateFormat('dd MMM'),
        intervalType: widget.period == '1D'
            ? DateTimeIntervalType.minutes
            : DateTimeIntervalType.days,
        interval: widget.period == '1D' ? 30 : 7,
        axisLine: const AxisLine(color: Color(0xFF1E2733)),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: isDark
              ? const Color(0xFF1E2733)
              : const Color(0xFFE2E6EA),
          dashArray: const [4, 4],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: GoogleFonts.robotoMono(
          fontSize: 9,
          color: const Color(0xFF8892A4),
        ),
      ),

      primaryYAxis: NumericAxis(
        opposedPosition: true, // Price axis on RIGHT like real apps
        numberFormat: NumberFormat('₹#,###', 'en_IN'),
        axisLine: const AxisLine(color: Color(0xFF1E2733)),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: isDark
              ? const Color(0xFF1E2733)
              : const Color(0xFFE2E6EA),
          dashArray: const [4, 4],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: GoogleFonts.robotoMono(
          fontSize: 9,
          color: const Color(0xFF8892A4),
        ),
      ),

      series: <CartesianSeries>[
        // ── CANDLESTICK SERIES ──
        CandleSeries<OHLCData, DateTime>(
          dataSource: _data,
          xValueMapper: (d, _) => d.time,
          openValueMapper: (d, _) => d.open,
          highValueMapper: (d, _) => d.high,
          lowValueMapper: (d, _) => d.low,
          closeValueMapper: (d, _) => d.close,

          // Bull candle (close > open)
          bullColor: const Color(0xFF00C853),
          // Bear candle (close < open)
          bearColor: const Color(0xFFFF3B3B),

          // Hollow candles for bull — like professional platforms
          enableSolidCandles: false,
          borderWidth: 1.5,

          // Wick styling
          animationDuration: 400,

          // Tooltip content
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),

        // ── 20-period Moving Average overlay ──
        if (_showMA20)
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeMA(20),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFFF8C00).withValues(alpha: 0.85),
            width: 1.3,
            dashArray: const [5, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            name: 'MA(20)',
            legendIconType: LegendIconType.horizontalLine,
          ),

        // ── 50-period Exponential Moving Average overlay ──
        if (_showEMA50)
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeEMA(50),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFF00D2FF).withValues(alpha: 0.85),
            width: 1.3,
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            name: 'EMA(50)',
          ),

        // ── Bollinger Bands ──
        if (_showBollinger) ...[
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeBollinger(20, true),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFC084FC).withValues(alpha: 0.70),
            width: 1.0,
            dashArray: const [3, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeBollinger(20, false),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFC084FC).withValues(alpha: 0.70),
            width: 1.0,
            dashArray: const [3, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ],
      ],
    );
  }

  // ── LINE CHART ─────────────────────────────────────────────────────────
  Widget _buildLineChart(bool isDark, Color chartColor) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,

      crosshairBehavior: CrosshairBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: CrosshairLineType.both,
        lineColor: const Color(0xFF8892A4).withValues(alpha: 0.50),
        lineWidth: 1,
        lineDashArray: const [4, 4],
      ),

      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFF1A1A2E),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 10, color: Colors.white),
          borderRadius: 6,
        ),
      ),

      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: _isPanZoomActive,
        enablePanning: _isPanZoomActive,
        enableDoubleTapZooming: _isPanZoomActive,
        enableSelectionZooming: false,
        zoomMode: ZoomMode.x,
      ),

      primaryXAxis: DateTimeAxis(
        dateFormat: widget.period == '1D'
            ? DateFormat('HH:mm')
            : DateFormat('dd MMM'),
        axisLine: const AxisLine(color: Color(0xFF1E2733)),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          dashArray: const [4, 4],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: GoogleFonts.robotoMono(
            fontSize: 9, color: const Color(0xFF8892A4)),
      ),

      primaryYAxis: NumericAxis(
        opposedPosition: true,
        numberFormat: NumberFormat('₹#,###', 'en_IN'),
        axisLine: const AxisLine(color: Color(0xFF1E2733)),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          dashArray: const [4, 4],
        ),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: GoogleFonts.robotoMono(
            fontSize: 9, color: const Color(0xFF8892A4)),
      ),

      series: <CartesianSeries>[
        // Gradient area under line
        AreaSeries<OHLCData, DateTime>(
          dataSource: _data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.close,
          gradient: LinearGradient(
            colors: [
              chartColor.withValues(alpha: 0.20),
              chartColor.withValues(alpha: 0.00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderWidth: 0,
          animationDuration: 400,
          markerSettings: const MarkerSettings(isVisible: false),
        ),

        // Main price line
        LineSeries<OHLCData, DateTime>(
          dataSource: _data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.close,
          color: chartColor,
          width: 2,
          animationDuration: 400,
          markerSettings: const MarkerSettings(
            isVisible: false,
          ),
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),

        // 20 MA overlay
        if (_showMA20)
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeMA(20),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFFF8C00).withValues(alpha: 0.85),
            width: 1.3,
            dashArray: const [5, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),

        // 50 EMA overlay
        if (_showEMA50)
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeEMA(50),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFF00D2FF).withValues(alpha: 0.85),
            width: 1.3,
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),

        // Bollinger Bands
        if (_showBollinger) ...[
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeBollinger(20, true),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFC084FC).withValues(alpha: 0.70),
            width: 1.0,
            dashArray: const [3, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
          LineSeries<OHLCData, DateTime>(
            dataSource: _computeBollinger(20, false),
            xValueMapper: (d, _) => d.time,
            yValueMapper: (d, _) => d.close,
            color: const Color(0xFFC084FC).withValues(alpha: 0.70),
            width: 1.0,
            dashArray: const [3, 3],
            animationDuration: 0,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ],
      ],
    );
  }

  // ── VOLUME CHART ─────────────────────────────────────────────────────────
  Widget _buildVolumeChart(bool isDark) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),

      primaryXAxis: const DateTimeAxis(
        isVisible: false,
        majorGridLines: MajorGridLines(width: 0),
      ),

      primaryYAxis: const NumericAxis(
        isVisible: false,
        majorGridLines: MajorGridLines(width: 0),
      ),

      series: <CartesianSeries>[
        ColumnSeries<OHLCData, DateTime>(
          dataSource: _data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.volume,
          pointColorMapper: (d, _) => d.isBullish
              ? const Color(0xFF00C853).withValues(alpha: 0.50)
              : const Color(0xFFFF3B3B).withValues(alpha: 0.50),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          animationDuration: 400,
          spacing: 0.1,
        ),
      ],
    );
  }

  // Compute Moving Average
  List<OHLCData> _computeMA(int period) {
    final result = <OHLCData>[];
    for (int i = period - 1; i < _data.length; i++) {
      final slice = _data.sublist(i - period + 1, i + 1);
      final avg = slice.map((d) => d.close).reduce((a, b) => a + b) / period;
      result.add(OHLCData(
        time: _data[i].time,
        open: avg, high: avg, low: avg, close: avg, volume: 0,
      ));
    }
    return result;
  }

  // Compute Exponential Moving Average (EMA)
  List<OHLCData> _computeEMA(int period) {
    if (_data.length < period) return [];
    final result = <OHLCData>[];
    final multiplier = 2.0 / (period + 1);
    double ema = _data.take(period).map((d) => d.close).reduce((a, b) => a + b) / period;

    for (int i = period - 1; i < _data.length; i++) {
      ema = (_data[i].close - ema) * multiplier + ema;
      result.add(OHLCData(
        time: _data[i].time,
        open: ema, high: ema, low: ema, close: ema, volume: 0,
      ));
    }
    return result;
  }

  // Compute Bollinger Bands (Upper / Lower)
  List<OHLCData> _computeBollinger(int period, bool isUpper) {
    final result = <OHLCData>[];
    for (int i = period - 1; i < _data.length; i++) {
      final slice = _data.sublist(i - period + 1, i + 1);
      final avg = slice.fold<double>(0.0, (acc, d) => acc + d.close) / period;
      final sumSq = slice.fold<double>(0.0, (acc, d) => acc + ((d.close - avg) * (d.close - avg)));
      final stdDev = sqrt(sumSq / period);
      final val = isUpper ? avg + (stdDev * 2) : avg - (stdDev * 2);
      result.add(OHLCData(
        time: _data[i].time,
        open: val, high: val, low: val, close: val, volume: 0,
      ));
    }
    return result;
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _ChartTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ChartTypeButton({
    required this.icon, required this.label,
    required this.isSelected, required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0066CC) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
            size: 14,
            color: isSelected ? Colors.white : const Color(0xFF8892A4)),
          const SizedBox(width: 4),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF8892A4),
            )),
        ],
      ),
    ),
  );
}

class _OHLCLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OHLCLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ',
        style: GoogleFonts.inter(
          fontSize: 9, color: const Color(0xFF8892A4))),
      Text(value,
        style: GoogleFonts.robotoMono(
          fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    ],
  );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
    child: Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        color: widget.color, shape: BoxShape.circle),
    ),
  );
}

class _IndicatorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool isDark;
  final IconData? icon;
  final VoidCallback onTap;

  const _IndicatorChip({
    required this.label,
    required this.color,
    required this.isActive,
    this.isDark = true,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? color.withValues(alpha: 0.20)
        : color.withValues(alpha: 0.14);
    final activeBorder = color;
    final inactiveBorder = isDark
        ? const Color(0xFF8892A4).withValues(alpha: 0.30)
        : const Color(0xFFCBD5E1);

    final textColor = isActive
        ? (isDark ? Colors.white : color)
        : (isDark ? const Color(0xFF8892A4) : const Color(0xFF475569));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeBorder : inactiveBorder,
            width: isActive ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: textColor),
              const SizedBox(width: 4),
            ] else ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : (isDark ? const Color(0xFF8892A4) : const Color(0xFF94A3B8)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
