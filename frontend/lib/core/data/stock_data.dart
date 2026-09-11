import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/ohlc_point.dart';

class StockModel {
  final String ticker;
  final String fullName;
  final String nseSymbol;
  final String bseCode;
  final String isin;
  final String exchange; // 'NSE', 'BSE', 'BOTH'
  final String sector;
  final String industry;
  final String logoUrl;
  final Color logoColor;
  final String websiteUrl;
  final double price;
  final double changePercent;
  final double changeAmount;
  final double previousClose;
  final double openPrice;
  final double dayHigh;
  final double dayLow;
  final String marketCap;
  final String peRatio;
  final String week52High;
  final String week52Low;
  final String volume;
  final List<FlSpot> chart1D;
  final List<FlSpot> chart1W;
  final List<FlSpot> chart1M;
  final List<FlSpot> chart1Y;
  final List<double> volumeData;
  final List<double> rsiData;
  final List<double> macdLine;
  final List<double> signalLine;
  final String aiSignal; // 'BUY', 'HOLD', 'SELL'
  final String aiReason;
  final List<String> searchKeywords;

  const StockModel({
    required this.ticker,
    required this.fullName,
    required this.nseSymbol,
    required this.bseCode,
    required this.isin,
    required this.exchange,
    required this.sector,
    required this.industry,
    required this.logoUrl,
    required this.logoColor,
    required this.websiteUrl,
    required this.price,
    required this.changePercent,
    required this.changeAmount,
    required this.previousClose,
    required this.openPrice,
    required this.dayHigh,
    required this.dayLow,
    required this.marketCap,
    required this.peRatio,
    required this.week52High,
    required this.week52Low,
    required this.volume,
    required this.chart1D,
    required this.chart1W,
    required this.chart1M,
    required this.chart1Y,
    required this.volumeData,
    required this.rsiData,
    required this.macdLine,
    required this.signalLine,
    required this.aiSignal,
    required this.aiReason,
    required this.searchKeywords,
  });

  bool get isPositive => changePercent >= 0;
  String get name => fullName;
  String get aiRecommendation => aiSignal;
  double get change => changeAmount;
  double get changePercentage => changePercent;
  double get sentimentScore => aiSignal == 'BUY' ? 0.88 : (aiSignal == 'SELL' ? 0.32 : 0.60);

  StockModel copyWith({
    String? ticker,
    String? fullName,
    String? nseSymbol,
    String? bseCode,
    String? isin,
    String? exchange,
    String? sector,
    String? industry,
    String? logoUrl,
    Color? logoColor,
    String? websiteUrl,
    double? price,
    double? changePercent,
    double? changeAmount,
    double? previousClose,
    double? openPrice,
    double? dayHigh,
    double? dayLow,
    String? marketCap,
    String? peRatio,
    String? week52High,
    String? week52Low,
    String? volume,
    List<FlSpot>? chart1D,
    List<FlSpot>? chart1W,
    List<FlSpot>? chart1M,
    List<FlSpot>? chart1Y,
    List<double>? volumeData,
    List<double>? rsiData,
    List<double>? macdLine,
    List<double>? signalLine,
    String? aiSignal,
    String? aiReason,
    List<String>? searchKeywords,
  }) {
    return StockModel(
      ticker: ticker ?? this.ticker,
      fullName: fullName ?? this.fullName,
      nseSymbol: nseSymbol ?? this.nseSymbol,
      bseCode: bseCode ?? this.bseCode,
      isin: isin ?? this.isin,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      logoUrl: logoUrl ?? this.logoUrl,
      logoColor: logoColor ?? this.logoColor,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      changeAmount: changeAmount ?? this.changeAmount,
      previousClose: previousClose ?? this.previousClose,
      openPrice: openPrice ?? this.openPrice,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      marketCap: marketCap ?? this.marketCap,
      peRatio: peRatio ?? this.peRatio,
      week52High: week52High ?? this.week52High,
      week52Low: week52Low ?? this.week52Low,
      volume: volume ?? this.volume,
      chart1D: chart1D ?? this.chart1D,
      chart1W: chart1W ?? this.chart1W,
      chart1M: chart1M ?? this.chart1M,
      chart1Y: chart1Y ?? this.chart1Y,
      volumeData: volumeData ?? this.volumeData,
      rsiData: rsiData ?? this.rsiData,
      macdLine: macdLine ?? this.macdLine,
      signalLine: signalLine ?? this.signalLine,
      aiSignal: aiSignal ?? this.aiSignal,
      aiReason: aiReason ?? this.aiReason,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  String get priceFormatted => formatINR(price);

  String get changePercentFormatted =>
      '${isPositive ? "+" : ""}${changePercent.toStringAsFixed(2)}%';

  String get changeAmountFormatted =>
      '${isPositive ? "+" : ""}₹${NumberFormat('#,##,##0.00', 'en_IN').format(changeAmount)}';

  String get technicalSummary {
    if (aiSignal == 'BUY') return 'Strong Buy';
    if (aiSignal == 'SELL') return 'Sell';
    return 'Neutral';
  }

  double get rsi => rsiData.isNotEmpty ? rsiData.last : 55.4;
  String get macd => macdLine.isNotEmpty && macdLine.last > 0 ? 'Bullish' : 'Neutral';
  String get support => '₹${(price * 0.96).toInt()}';
  String get resistance => '₹${(price * 1.04).toInt()}';

  String get high52 => week52High;
  String get low52 => week52Low;
  List<FlSpot> get chartData => chart1D;

  List<FlSpot> getChartSpots(String period) {
    switch (period) {
      case '1W':
        return chart1W;
      case '1M':
        return chart1M;
      case '1Y':
      case '3M':
      case '6M':
      case '5Y':
      case 'MAX':
        return chart1Y;
      case '1D':
      default:
        return chart1D;
    }
  }

  List<OhlcPoint> getOhlcPoints(String period) {
    final now = DateTime.now();
    final spots = getChartSpots(period);

    return List.generate(spots.length, (i) {
      final close = spots[i].y;
      final prevClose = i > 0 ? spots[i - 1].y : close * 0.995;
      final open = prevClose;
      final high = math.max(open, close) * 1.004;
      final low = math.min(open, close) * 0.996;
      final time = now.subtract(
        Duration(days: (spots.length - 1 - i) * (period == '1D' ? 1 : 5)),
      );
      return OhlcPoint(
        time: time,
        open: open,
        high: high,
        low: low,
        close: close,
      );
    });
  }

  static String formatINR(double val) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${fmt.format(val)}';
  }
}

class StockRepository {
  static final List<StockModel> stocks = [
    StockModel(
      ticker: 'RELIANCE',
      fullName: 'Reliance Industries Ltd.',
      nseSymbol: 'RELIANCE',
      bseCode: '500325',
      isin: 'INE002A01018',
      exchange: 'BOTH',
      sector: 'Energy',
      industry: 'Oil & Gas Refining',
      logoUrl: 'https://logo.clearbit.com/ril.com',
      logoColor: AppColors.logoReliance,
      websiteUrl: 'https://www.ril.com',
      price: 2891.00,
      changePercent: 1.24,
      changeAmount: 35.40,
      previousClose: 2855.60,
      openPrice: 2860.00,
      dayHigh: 2898.50,
      dayLow: 2845.00,
      marketCap: '₹19,55,420 Cr',
      peRatio: '28.4',
      week52High: '₹3,024.90',
      week52Low: '₹2,220.30',
      volume: '1.24 Cr',
      chart1D: const [
        FlSpot(0, 2855.6),
        FlSpot(1, 2862.0),
        FlSpot(2, 2870.5),
        FlSpot(3, 2865.0),
        FlSpot(4, 2880.0),
        FlSpot(5, 2885.5),
        FlSpot(6, 2891.0),
      ],
      chart1W: const [
        FlSpot(0, 2810.0),
        FlSpot(1, 2830.0),
        FlSpot(2, 2845.0),
        FlSpot(3, 2835.0),
        FlSpot(4, 2860.0),
        FlSpot(5, 2875.0),
        FlSpot(6, 2891.0),
      ],
      chart1M: const [
        FlSpot(0, 2720.0),
        FlSpot(1, 2750.0),
        FlSpot(2, 2780.0),
        FlSpot(3, 2810.0),
        FlSpot(4, 2840.0),
        FlSpot(5, 2865.0),
        FlSpot(6, 2891.0),
      ],
      chart1Y: const [
        FlSpot(0, 2350.0),
        FlSpot(1, 2480.0),
        FlSpot(2, 2600.0),
        FlSpot(3, 2750.0),
        FlSpot(4, 2820.0),
        FlSpot(5, 2980.0),
        FlSpot(6, 2891.0),
      ],
      volumeData: const [12.4, 15.2, 11.8, 9.4, 16.8, 14.5, 18.2],
      rsiData: const [45, 52, 58, 54, 60, 63, 62.4],
      macdLine: const [1.2, 2.4, 3.8, 3.1, 4.5, 5.2, 6.1],
      signalLine: const [0.8, 1.5, 2.2, 2.8, 3.4, 4.1, 4.8],
      aiSignal: 'BUY',
      aiReason: 'Reliance shows strong upward momentum. RSI at 62.4 — clean breakout pattern with support at ₹2,845.',
      searchKeywords: const ['reliance', 'ril', 'jio', 'petroleum', '500325', 'ine002a01018'],
    ),
    StockModel(
      ticker: 'TCS',
      fullName: 'Tata Consultancy Services',
      nseSymbol: 'TCS',
      bseCode: '532540',
      isin: 'INE467B01029',
      exchange: 'BOTH',
      sector: 'Information Technology',
      industry: 'IT Services & Consulting',
      logoUrl: 'https://logo.clearbit.com/tcs.com',
      logoColor: AppColors.logoTCS,
      websiteUrl: 'https://www.tcs.com',
      price: 3542.00,
      changePercent: -0.83,
      changeAmount: -29.60,
      previousClose: 3571.60,
      openPrice: 3565.00,
      dayHigh: 3580.00,
      dayLow: 3535.00,
      marketCap: '₹12,81,300 Cr',
      peRatio: '29.1',
      week52High: '₹4,254.75',
      week52Low: '₹3,313.00',
      volume: '45.2 Lakh',
      chart1D: const [
        FlSpot(0, 3571.6),
        FlSpot(1, 3565.0),
        FlSpot(2, 3550.0),
        FlSpot(3, 3560.0),
        FlSpot(4, 3545.0),
        FlSpot(5, 3555.0),
        FlSpot(6, 3542.0),
      ],
      chart1W: const [
        FlSpot(0, 3620.0),
        FlSpot(1, 3600.0),
        FlSpot(2, 3580.0),
        FlSpot(3, 3590.0),
        FlSpot(4, 3560.0),
        FlSpot(5, 3550.0),
        FlSpot(6, 3542.0),
      ],
      chart1M: const [
        FlSpot(0, 3750.0),
        FlSpot(1, 3710.0),
        FlSpot(2, 3680.0),
        FlSpot(3, 3650.0),
        FlSpot(4, 3610.0),
        FlSpot(5, 3570.0),
        FlSpot(6, 3542.0),
      ],
      chart1Y: const [
        FlSpot(0, 3200.0),
        FlSpot(1, 3450.0),
        FlSpot(2, 3800.0),
        FlSpot(3, 4100.0),
        FlSpot(4, 3950.0),
        FlSpot(5, 3700.0),
        FlSpot(6, 3542.0),
      ],
      volumeData: const [8.5, 9.2, 10.1, 7.8, 8.9, 9.5, 7.2],
      rsiData: const [60, 56, 52, 54, 50, 49, 48.1],
      macdLine: const [3.5, 2.8, 2.1, 1.9, 1.2, 0.8, 0.4],
      signalLine: const [2.8, 2.5, 2.2, 1.8, 1.4, 1.1, 0.7],
      aiSignal: 'HOLD',
      aiReason: 'TCS is consolidating near key support. Wait for IT sector clarity before fresh long entries.',
      searchKeywords: const ['tcs', 'tata consultancy', 'tata', 'it', '532540'],
    ),
    StockModel(
      ticker: 'HDFCBANK',
      fullName: 'HDFC Bank Ltd.',
      nseSymbol: 'HDFCBANK',
      bseCode: '500180',
      isin: 'INE040A01034',
      exchange: 'BOTH',
      sector: 'Banking',
      industry: 'Private Sector Bank',
      logoUrl: 'https://logo.clearbit.com/hdfcbank.com',
      logoColor: AppColors.logoHDFC,
      websiteUrl: 'https://www.hdfcbank.com',
      price: 1724.00,
      changePercent: 2.31,
      changeAmount: 38.90,
      previousClose: 1685.10,
      openPrice: 1690.00,
      dayHigh: 1730.00,
      dayLow: 1688.00,
      marketCap: '₹13,10,400 Cr',
      peRatio: '19.8',
      week52High: '₹1,794.00',
      week52Low: '₹1,363.55',
      volume: '1.85 Cr',
      chart1D: const [
        FlSpot(0, 1685.1),
        FlSpot(1, 1692.0),
        FlSpot(2, 1705.0),
        FlSpot(3, 1698.0),
        FlSpot(4, 1715.0),
        FlSpot(5, 1720.0),
        FlSpot(6, 1724.0),
      ],
      chart1W: const [
        FlSpot(0, 1640.0),
        FlSpot(1, 1655.0),
        FlSpot(2, 1670.0),
        FlSpot(3, 1685.0),
        FlSpot(4, 1700.0),
        FlSpot(5, 1710.0),
        FlSpot(6, 1724.0),
      ],
      chart1M: const [
        FlSpot(0, 1580.0),
        FlSpot(1, 1605.0),
        FlSpot(2, 1630.0),
        FlSpot(3, 1650.0),
        FlSpot(4, 1680.0),
        FlSpot(5, 1700.0),
        FlSpot(6, 1724.0),
      ],
      chart1Y: const [
        FlSpot(0, 1420.0),
        FlSpot(1, 1480.0),
        FlSpot(2, 1540.0),
        FlSpot(3, 1620.0),
        FlSpot(4, 1680.0),
        FlSpot(5, 1750.0),
        FlSpot(6, 1724.0),
      ],
      volumeData: const [22.1, 19.4, 25.8, 28.2, 31.0, 27.5, 34.2],
      rsiData: const [48, 54, 59, 62, 65, 66, 68.2],
      macdLine: const [2.1, 3.5, 4.8, 6.2, 7.5, 8.9, 10.2],
      signalLine: const [1.2, 2.1, 3.2, 4.5, 5.8, 7.1, 8.4],
      aiSignal: 'BUY',
      aiReason: 'Strong NPA improvement and credit growth accelerating. Major bullish breakout candidate above ₹1,700.',
      searchKeywords: const ['hdfc', 'hdfcbank', 'bank', 'banking', '500180'],
    ),
    StockModel(
      ticker: 'INFY',
      fullName: 'Infosys Ltd.',
      nseSymbol: 'INFY',
      bseCode: '500209',
      isin: 'INE009A01021',
      exchange: 'BOTH',
      sector: 'Information Technology',
      industry: 'IT Services & Software',
      logoUrl: 'https://logo.clearbit.com/infosys.com',
      logoColor: AppColors.logoInfosys,
      websiteUrl: 'https://www.infosys.com',
      price: 1788.00,
      changePercent: 0.52,
      changeAmount: 9.25,
      previousClose: 1778.75,
      openPrice: 1780.00,
      dayHigh: 1795.00,
      dayLow: 1772.00,
      marketCap: '₹7,42,100 Cr',
      peRatio: '27.4',
      week52High: '₹1,975.00',
      week52Low: '₹1,355.00',
      volume: '88.5 Lakh',
      chart1D: const [
        FlSpot(0, 1778.7),
        FlSpot(1, 1782.0),
        FlSpot(2, 1780.0),
        FlSpot(3, 1785.0),
        FlSpot(4, 1782.0),
        FlSpot(5, 1790.0),
        FlSpot(6, 1788.0),
      ],
      chart1W: const [
        FlSpot(0, 1740.0),
        FlSpot(1, 1755.0),
        FlSpot(2, 1750.0),
        FlSpot(3, 1770.0),
        FlSpot(4, 1765.0),
        FlSpot(5, 1780.0),
        FlSpot(6, 1788.0),
      ],
      chart1M: const [
        FlSpot(0, 1680.0),
        FlSpot(1, 1710.0),
        FlSpot(2, 1735.0),
        FlSpot(3, 1750.0),
        FlSpot(4, 1765.0),
        FlSpot(5, 1775.0),
        FlSpot(6, 1788.0),
      ],
      chart1Y: const [
        FlSpot(0, 1380.0),
        FlSpot(1, 1450.0),
        FlSpot(2, 1560.0),
        FlSpot(3, 1680.0),
        FlSpot(4, 1820.0),
        FlSpot(5, 1890.0),
        FlSpot(6, 1788.0),
      ],
      volumeData: const [14.2, 12.8, 15.6, 13.9, 16.4, 14.8, 17.1],
      rsiData: const [50, 52, 51, 55, 54, 56, 56.8],
      macdLine: const [1.8, 2.1, 2.0, 2.5, 2.4, 2.8, 3.1],
      signalLine: const [1.5, 1.7, 1.9, 2.1, 2.2, 2.4, 2.6],
      aiSignal: 'BUY',
      aiReason: 'Infosys shows steady accumulation by institutional investors. Target ₹1,850 in near term.',
      searchKeywords: const ['infosys', 'infy', 'it', 'software', '500209'],
    ),
    StockModel(
      ticker: 'WIPRO',
      fullName: 'Wipro Ltd.',
      nseSymbol: 'WIPRO',
      bseCode: '507685',
      isin: 'INE075A01022',
      exchange: 'BOTH',
      sector: 'Information Technology',
      industry: 'IT Services',
      logoUrl: 'https://logo.clearbit.com/wipro.com',
      logoColor: AppColors.logoWipro,
      websiteUrl: 'https://www.wipro.com',
      price: 548.00,
      changePercent: -1.12,
      changeAmount: -6.20,
      previousClose: 554.20,
      openPrice: 552.00,
      dayHigh: 556.00,
      dayLow: 544.00,
      marketCap: '₹2,86,400 Cr',
      peRatio: '23.6',
      week52High: '₹580.00',
      week52Low: '₹375.00',
      volume: '62.4 Lakh',
      chart1D: const [
        FlSpot(0, 554.2),
        FlSpot(1, 552.0),
        FlSpot(2, 550.0),
        FlSpot(3, 553.0),
        FlSpot(4, 549.0),
        FlSpot(5, 550.0),
        FlSpot(6, 548.0),
      ],
      chart1W: const [
        FlSpot(0, 570.0),
        FlSpot(1, 565.0),
        FlSpot(2, 560.0),
        FlSpot(3, 555.0),
        FlSpot(4, 558.0),
        FlSpot(5, 552.0),
        FlSpot(6, 548.0),
      ],
      chart1M: const [
        FlSpot(0, 520.0),
        FlSpot(1, 535.0),
        FlSpot(2, 550.0),
        FlSpot(3, 560.0),
        FlSpot(4, 565.0),
        FlSpot(5, 555.0),
        FlSpot(6, 548.0),
      ],
      chart1Y: const [
        FlSpot(0, 390.0),
        FlSpot(1, 420.0),
        FlSpot(2, 460.0),
        FlSpot(3, 510.0),
        FlSpot(4, 560.0),
        FlSpot(5, 575.0),
        FlSpot(6, 548.0),
      ],
      volumeData: const [6.8, 7.4, 8.1, 6.2, 7.0, 8.5, 9.2],
      rsiData: const [52, 48, 46, 44, 45, 43, 41.3],
      macdLine: const [0.8, 0.4, -0.1, -0.5, -0.4, -0.8, -1.2],
      signalLine: const [0.6, 0.5, 0.2, -0.1, -0.2, -0.5, -0.8],
      aiSignal: 'SELL',
      aiReason: 'Margin headwinds impacting short-term performance. Watch for reversal signals around ₹530.',
      searchKeywords: const ['wipro', 'it', 'software', '507685'],
    ),
    StockModel(
      ticker: 'SBIN',
      fullName: 'State Bank of India',
      nseSymbol: 'SBIN',
      bseCode: '500112',
      isin: 'INE062A01020',
      exchange: 'BOTH',
      sector: 'Banking',
      industry: 'Public Sector Bank',
      logoUrl: 'https://logo.clearbit.com/sbi.co.in',
      logoColor: AppColors.logoSBI,
      websiteUrl: 'https://www.sbi.co.in',
      price: 812.00,
      changePercent: 0.94,
      changeAmount: 7.55,
      previousClose: 804.45,
      openPrice: 806.00,
      dayHigh: 815.00,
      dayLow: 802.00,
      marketCap: '₹7,24,680 Cr',
      peRatio: '11.4',
      week52High: '₹912.00',
      week52Low: '₹560.00',
      volume: '1.42 Cr',
      chart1D: const [
        FlSpot(0, 804.4),
        FlSpot(1, 806.0),
        FlSpot(2, 808.5),
        FlSpot(3, 805.0),
        FlSpot(4, 810.0),
        FlSpot(5, 811.5),
        FlSpot(6, 812.0),
      ],
      chart1W: const [
        FlSpot(0, 780.0),
        FlSpot(1, 790.0),
        FlSpot(2, 785.0),
        FlSpot(3, 800.0),
        FlSpot(4, 805.0),
        FlSpot(5, 808.0),
        FlSpot(6, 812.0),
      ],
      chart1M: const [
        FlSpot(0, 750.0),
        FlSpot(1, 765.0),
        FlSpot(2, 780.0),
        FlSpot(3, 790.0),
        FlSpot(4, 800.0),
        FlSpot(5, 808.0),
        FlSpot(6, 812.0),
      ],
      chart1Y: const [
        FlSpot(0, 580.0),
        FlSpot(1, 640.0),
        FlSpot(2, 720.0),
        FlSpot(3, 810.0),
        FlSpot(4, 880.0),
        FlSpot(5, 850.0),
        FlSpot(6, 812.0),
      ],
      volumeData: const [18.5, 21.2, 19.8, 24.5, 22.8, 26.1, 28.4],
      rsiData: const [51, 55, 53, 58, 59, 60, 61.2],
      macdLine: const [2.5, 3.1, 3.0, 3.8, 4.2, 4.6, 5.1],
      signalLine: const [1.8, 2.2, 2.5, 3.0, 3.4, 3.8, 4.2],
      aiSignal: 'BUY',
      aiReason: 'PSU banking sector rally continuing. SBIN holding above key 50-day moving average.',
      searchKeywords: const ['sbi', 'sbin', 'state bank', 'bank', '500112'],
    ),
    StockModel(
      ticker: 'ICICIBANK',
      fullName: 'ICICI Bank Ltd.',
      nseSymbol: 'ICICIBANK',
      bseCode: '532174',
      isin: 'INE090A01021',
      exchange: 'BOTH',
      sector: 'Banking',
      industry: 'Private Sector Bank',
      logoUrl: 'https://logo.clearbit.com/icicibank.com',
      logoColor: const Color(0xFFD97706),
      websiteUrl: 'https://www.icicibank.com',
      price: 1214.30,
      changePercent: 1.48,
      changeAmount: 17.70,
      previousClose: 1196.60,
      openPrice: 1200.00,
      dayHigh: 1218.00,
      dayLow: 1195.00,
      marketCap: '₹8,54,120 Cr',
      peRatio: '18.2',
      week52High: '₹1,258.00',
      week52Low: '₹928.00',
      volume: '98.2 Lakh',
      chart1D: const [
        FlSpot(0, 1196.6),
        FlSpot(1, 1202.0),
        FlSpot(2, 1205.0),
        FlSpot(3, 1208.0),
        FlSpot(4, 1210.0),
        FlSpot(5, 1212.5),
        FlSpot(6, 1214.3),
      ],
      chart1W: const [
        FlSpot(0, 1170.0),
        FlSpot(1, 1180.0),
        FlSpot(2, 1190.0),
        FlSpot(3, 1185.0),
        FlSpot(4, 1200.0),
        FlSpot(5, 1208.0),
        FlSpot(6, 1214.3),
      ],
      chart1M: const [
        FlSpot(0, 1120.0),
        FlSpot(1, 1140.0),
        FlSpot(2, 1160.0),
        FlSpot(3, 1175.0),
        FlSpot(4, 1190.0),
        FlSpot(5, 1205.0),
        FlSpot(6, 1214.3),
      ],
      chart1Y: const [
        FlSpot(0, 950.0),
        FlSpot(1, 1010.0),
        FlSpot(2, 1080.0),
        FlSpot(3, 1140.0),
        FlSpot(4, 1210.0),
        FlSpot(5, 1240.0),
        FlSpot(6, 1214.3),
      ],
      volumeData: const [15.4, 18.2, 17.1, 21.0, 19.5, 23.4, 25.8],
      rsiData: const [54, 58, 60, 63, 62, 64, 65.5],
      macdLine: const [3.2, 4.1, 4.8, 5.6, 5.5, 6.4, 7.2],
      signalLine: const [2.1, 2.8, 3.5, 4.2, 4.6, 5.3, 6.0],
      aiSignal: 'BUY',
      aiReason: 'Robust net interest margins and digital growth driving strong outperformance.',
      searchKeywords: const ['icici', 'icicibank', 'bank', '532174'],
    ),
    StockModel(
      ticker: 'ZOMATO',
      fullName: 'Zomato Ltd.',
      nseSymbol: 'ZOMATO',
      bseCode: '543320',
      isin: 'INE758T01015',
      exchange: 'BOTH',
      sector: 'Consumer Services',
      industry: 'Online Food Delivery & Quick Commerce',
      logoUrl: 'https://logo.clearbit.com/zomato.com',
      logoColor: const Color(0xFFE23744),
      websiteUrl: 'https://www.zomato.com',
      price: 264.30,
      changePercent: 4.12,
      changeAmount: 10.45,
      previousClose: 253.85,
      openPrice: 256.00,
      dayHigh: 268.00,
      dayLow: 254.50,
      marketCap: '₹2,34,500 Cr',
      peRatio: '112.5',
      week52High: '₹298.00',
      week52Low: '₹88.00',
      volume: '4.85 Cr',
      chart1D: const [
        FlSpot(0, 253.8),
        FlSpot(1, 257.0),
        FlSpot(2, 260.5),
        FlSpot(3, 258.0),
        FlSpot(4, 262.0),
        FlSpot(5, 265.0),
        FlSpot(6, 264.3),
      ],
      chart1W: const [
        FlSpot(0, 240.0),
        FlSpot(1, 245.0),
        FlSpot(2, 250.0),
        FlSpot(3, 248.0),
        FlSpot(4, 255.0),
        FlSpot(5, 260.0),
        FlSpot(6, 264.3),
      ],
      chart1M: const [
        FlSpot(0, 210.0),
        FlSpot(1, 222.0),
        FlSpot(2, 235.0),
        FlSpot(3, 245.0),
        FlSpot(4, 250.0),
        FlSpot(5, 258.0),
        FlSpot(6, 264.3),
      ],
      chart1Y: const [
        FlSpot(0, 95.0),
        FlSpot(1, 130.0),
        FlSpot(2, 165.0),
        FlSpot(3, 210.0),
        FlSpot(4, 250.0),
        FlSpot(5, 280.0),
        FlSpot(6, 264.3),
      ],
      volumeData: const [32.1, 45.8, 39.2, 51.4, 48.0, 54.2, 61.5],
      rsiData: const [58, 62, 65, 68, 70, 72, 74.1],
      macdLine: const [4.2, 5.8, 7.1, 8.5, 9.4, 10.8, 12.1],
      signalLine: const [3.0, 4.2, 5.4, 6.8, 7.9, 9.1, 10.4],
      aiSignal: 'BUY',
      aiReason: 'Blinkit quick commerce expansion accelerating profitability. High momentum play.',
      searchKeywords: const ['zomato', 'blinkit', 'food', 'delivery', '543320'],
    ),
    StockModel(
      ticker: 'TATAMOTORS',
      fullName: 'Tata Motors Ltd.',
      nseSymbol: 'TATAMOTORS',
      bseCode: '500570',
      isin: 'INE155A01022',
      exchange: 'BOTH',
      sector: 'Automobile',
      industry: 'Passenger Vehicles & Commercial Vehicles',
      logoUrl: 'https://logo.clearbit.com/tatamotors.com',
      logoColor: const Color(0xFF1E3A8A),
      websiteUrl: 'https://www.tatamotors.com',
      price: 982.40,
      changePercent: 2.57,
      changeAmount: 24.60,
      previousClose: 957.80,
      openPrice: 962.00,
      dayHigh: 988.00,
      dayLow: 958.00,
      marketCap: '₹3,26,400 Cr',
      peRatio: '10.8',
      week52High: '₹1,179.00',
      week52Low: '₹592.00',
      volume: '1.12 Cr',
      chart1D: const [
        FlSpot(0, 957.8),
        FlSpot(1, 963.0),
        FlSpot(2, 970.0),
        FlSpot(3, 968.0),
        FlSpot(4, 975.0),
        FlSpot(5, 980.0),
        FlSpot(6, 982.4),
      ],
      chart1W: const [
        FlSpot(0, 930.0),
        FlSpot(1, 942.0),
        FlSpot(2, 950.0),
        FlSpot(3, 955.0),
        FlSpot(4, 965.0),
        FlSpot(5, 975.0),
        FlSpot(6, 982.4),
      ],
      chart1M: const [
        FlSpot(0, 890.0),
        FlSpot(1, 915.0),
        FlSpot(2, 930.0),
        FlSpot(3, 945.0),
        FlSpot(4, 960.0),
        FlSpot(5, 972.0),
        FlSpot(6, 982.4),
      ],
      chart1Y: const [
        FlSpot(0, 610.0),
        FlSpot(1, 710.0),
        FlSpot(2, 820.0),
        FlSpot(3, 940.0),
        FlSpot(4, 1050.0),
        FlSpot(5, 1020.0),
        FlSpot(6, 982.4),
      ],
      volumeData: const [14.2, 16.8, 15.1, 18.4, 17.5, 20.2, 22.4],
      rsiData: const [52, 56, 59, 61, 64, 66, 67.5],
      macdLine: const [3.1, 4.2, 5.5, 6.8, 7.9, 8.8, 9.7],
      signalLine: const [2.0, 3.1, 4.2, 5.3, 6.4, 7.5, 8.4],
      aiSignal: 'BUY',
      aiReason: 'JLR free cash flow generation robust. Demerger into commercial & passenger vehicle entities creates value.',
      searchKeywords: const ['tata motors', 'tatamotors', 'jlr', 'ev', 'auto', '500570'],
    ),
    StockModel(
      ticker: 'MARUTI',
      fullName: 'Maruti Suzuki India Ltd.',
      nseSymbol: 'MARUTI',
      bseCode: '532500',
      isin: 'INE585B01010',
      exchange: 'BOTH',
      sector: 'Automobile',
      industry: 'Passenger Vehicles',
      logoUrl: 'https://logo.clearbit.com/marutisuzuki.com',
      logoColor: const Color(0xFFDC2626),
      websiteUrl: 'https://www.marutisuzuki.com',
      price: 12480.60,
      changePercent: 2.03,
      changeAmount: 248.20,
      previousClose: 12232.40,
      openPrice: 12280.00,
      dayHigh: 12540.00,
      dayLow: 12250.00,
      marketCap: '₹3,76,800 Cr',
      peRatio: '27.8',
      week52High: '₹13,680.00',
      week52Low: '₹9,250.00',
      volume: '4.2 Lakh',
      chart1D: const [
        FlSpot(0, 12232.4),
        FlSpot(1, 12290.0),
        FlSpot(2, 12350.0),
        FlSpot(3, 12320.0),
        FlSpot(4, 12410.0),
        FlSpot(5, 12450.0),
        FlSpot(6, 12480.6),
      ],
      chart1W: const [
        FlSpot(0, 11950.0),
        FlSpot(1, 12100.0),
        FlSpot(2, 12200.0),
        FlSpot(3, 12150.0),
        FlSpot(4, 12300.0),
        FlSpot(5, 12400.0),
        FlSpot(6, 12480.6),
      ],
      chart1M: const [
        FlSpot(0, 11500.0),
        FlSpot(1, 11750.0),
        FlSpot(2, 11950.0),
        FlSpot(3, 12100.0),
        FlSpot(4, 12300.0),
        FlSpot(5, 12420.0),
        FlSpot(6, 12480.6),
      ],
      chart1Y: const [
        FlSpot(0, 9400.0),
        FlSpot(1, 10200.0),
        FlSpot(2, 11100.0),
        FlSpot(3, 12200.0),
        FlSpot(4, 13200.0),
        FlSpot(5, 12800.0),
        FlSpot(6, 12480.6),
      ],
      volumeData: const [4.1, 4.5, 4.2, 4.8, 5.1, 4.9, 5.4],
      rsiData: const [54, 57, 60, 62, 64, 65, 66.2],
      macdLine: const [12.4, 15.8, 18.2, 21.0, 24.5, 27.2, 29.8],
      signalLine: const [10.1, 12.8, 15.2, 18.1, 21.0, 23.8, 26.4],
      aiSignal: 'BUY',
      aiReason: 'SUV market share gain driving margin expansion. Hybrid vehicle strategy outperforming peers.',
      searchKeywords: const ['maruti', 'suzuki', 'auto', 'car', '532500'],
    ),
  ];

  static StockModel getStock(String query) {
    final q = query.trim().toUpperCase();
    return stocks.firstWhere(
      (s) =>
          s.ticker.toUpperCase() == q ||
          s.nseSymbol.toUpperCase() == q ||
          s.bseCode == q,
      orElse: () => stocks.first,
    );
  }

  static List<StockModel> searchStocks(String query) {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return stocks;

    // Helper to check if ticker, symbol, or any word in full name starts with query
    bool startsWithQuery(StockModel s) {
      final t = s.ticker.toLowerCase();
      final nse = s.nseSymbol.toLowerCase();
      final nameWords = s.fullName.toLowerCase().split(RegExp(r'[\s\.\,\-]+'));

      if (t.startsWith(cleanQ) || nse.startsWith(cleanQ)) return true;
      for (final word in nameWords) {
        if (word.startsWith(cleanQ)) return true;
      }
      return false;
    }

    // Sort results: exact prefix matches first
    final exactPrefixMatches = stocks.where(startsWithQuery).toList();

    // For short queries (1 or 2 characters), return ONLY prefix matches (e.g. 'm' -> Maruti, Tata Motors)
    if (cleanQ.length <= 2) {
      return exactPrefixMatches;
    }

    // For 3+ character queries, add secondary contains matches if not already included
    final secondaryMatches = stocks.where((s) {
      if (exactPrefixMatches.contains(s)) return false;
      final t = s.ticker.toLowerCase();
      final n = s.fullName.toLowerCase();
      final nse = s.nseSymbol.toLowerCase();
      final bse = s.bseCode.toLowerCase();
      final sector = s.sector.toLowerCase();

      return t.contains(cleanQ) ||
             n.contains(cleanQ) ||
             nse.contains(cleanQ) ||
             bse.contains(cleanQ) ||
             sector.contains(cleanQ);
    }).toList();

    return [...exactPrefixMatches, ...secondaryMatches];
  }
}
