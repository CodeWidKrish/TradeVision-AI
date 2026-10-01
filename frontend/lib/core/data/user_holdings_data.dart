import 'package:flutter/material.dart';
import 'stock_data.dart';
import '../providers/portfolio_provider.dart';

class UserHoldingItem {
  final String ticker;
  final String name;
  final int quantity;
  final double avgBuyPrice;
  final String sector;
  final Color color;

  const UserHoldingItem({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.avgBuyPrice,
    required this.sector,
    required this.color,
  });

  double get invested => quantity * avgBuyPrice;
}

class PortfolioSnapshot {
  final double totalStockValue;
  final double cashReserve;
  final double totalPortfolioValue;
  final double totalInvested;
  final double totalReturns;
  final double returnsPercent;
  final double todayGain;
  final double todayPercent;
  final List<UserHoldingItem> allHoldings;
  final Map<String, double> holdingCurrentPrices;
  final Map<String, double> holdingCurrentValues;
  final Map<String, double> sectorBreakdown; // Sector -> Total Current Value

  const PortfolioSnapshot({
    required this.totalStockValue,
    required this.cashReserve,
    required this.totalPortfolioValue,
    required this.totalInvested,
    required this.totalReturns,
    required this.returnsPercent,
    required this.todayGain,
    required this.todayPercent,
    required this.allHoldings,
    required this.holdingCurrentPrices,
    required this.holdingCurrentValues,
    required this.sectorBreakdown,
  });
}

class UserHoldingsRepository {
  static const double cashReserve = 10288.0;

  static const List<UserHoldingItem> defaultHoldings = [
    UserHoldingItem(
      ticker: 'RELIANCE',
      name: 'Reliance Industries',
      quantity: 120,
      avgBuyPrice: 1180.00,
      sector: 'Energy',
      color: Color(0xFF0066CC),
    ),
    UserHoldingItem(
      ticker: 'HDFCBANK',
      name: 'HDFC Bank',
      quantity: 65,
      avgBuyPrice: 1610.00,
      sector: 'Banking',
      color: Color(0xFF00C853),
    ),
    UserHoldingItem(
      ticker: 'TCS',
      name: 'Tata Consultancy Services',
      quantity: 25,
      avgBuyPrice: 3350.00,
      sector: 'IT',
      color: Color(0xFFFF8C00),
    ),
    UserHoldingItem(
      ticker: 'INFY',
      name: 'Infosys',
      quantity: 30,
      avgBuyPrice: 1680.00,
      sector: 'IT',
      color: Color(0xFF38BDF8),
    ),
    UserHoldingItem(
      ticker: 'SBIN',
      name: 'State Bank of India',
      quantity: 40,
      avgBuyPrice: 740.00,
      sector: 'Banking',
      color: Color(0xFFA855F7),
    ),
    UserHoldingItem(
      ticker: 'TATAMOTORS',
      name: 'Tata Motors',
      quantity: 35,
      avgBuyPrice: 890.00,
      sector: 'Automobile',
      color: Color(0xFFEC4899),
    ),
  ];

  static PortfolioSnapshot computeSnapshot({PortfolioProvider? portfolioProvider}) {
    double totalStockValue = 0.0;
    double totalInvested = 0.0;
    double todayGain = 0.0;

    final List<UserHoldingItem> holdings = List.from(defaultHoldings);
    final Map<String, double> holdingCurrentPrices = {};
    final Map<String, double> holdingCurrentValues = {};
    final Map<String, double> sectorBreakdown = {};

    // 1. Process base holdings
    for (final h in holdings) {
      final stock = StockRepository.getStock(h.ticker);
      final livePrice = stock.price > 0 ? stock.price : (h.avgBuyPrice * 1.15);
      final liveVal = livePrice * h.quantity;
      totalStockValue += liveVal;
      totalInvested += h.invested;
      todayGain += stock.changeAmount * h.quantity;

      holdingCurrentPrices[h.ticker] = livePrice;
      holdingCurrentValues[h.ticker] = liveVal;
      sectorBreakdown[h.sector] = (sectorBreakdown[h.sector] ?? 0.0) + liveVal;
    }

    // 2. Include paper trading positions if present
    if (portfolioProvider != null) {
      for (final pos in portfolioProvider.positions.values) {
        final stock = StockRepository.getStock(pos.ticker);
        final livePrice = stock.price > 0 ? stock.price : pos.avgPrice;
        final liveVal = livePrice * pos.quantity;
        totalStockValue += liveVal;
        totalInvested += pos.totalInvested;
        todayGain += stock.changeAmount * pos.quantity;

        final existingIdx = holdings.indexWhere((item) => item.ticker == pos.ticker);
        if (existingIdx != -1) {
          final existing = holdings[existingIdx];
          final combinedQty = existing.quantity + pos.quantity;
          final combinedInvested = existing.invested + pos.totalInvested;
          final combinedAvg = combinedQty > 0 ? combinedInvested / combinedQty : existing.avgBuyPrice;
          holdings[existingIdx] = UserHoldingItem(
            ticker: existing.ticker,
            name: existing.name,
            quantity: combinedQty,
            avgBuyPrice: combinedAvg,
            sector: existing.sector,
            color: existing.color,
          );
        } else {
          holdings.add(UserHoldingItem(
            ticker: pos.ticker,
            name: pos.stockName.isNotEmpty ? pos.stockName : stock.name,
            quantity: pos.quantity,
            avgBuyPrice: pos.avgPrice,
            sector: stock.sector.isNotEmpty ? stock.sector : 'General Equity',
            color: stock.logoColor,
          ));
        }

        holdingCurrentPrices[pos.ticker] = livePrice;
        holdingCurrentValues[pos.ticker] = (holdingCurrentValues[pos.ticker] ?? 0.0) + liveVal;
        final sec = stock.sector.isNotEmpty ? stock.sector : 'General Equity';
        sectorBreakdown[sec] = (sectorBreakdown[sec] ?? 0.0) + liveVal;
      }
    }

    final double totalPortfolioValue = totalStockValue + cashReserve;
    final double totalReturns = totalPortfolioValue - totalInvested;
    final double returnsPercent =
        totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;
    final double todayPercent = (totalPortfolioValue - todayGain) > 0
        ? (todayGain / (totalPortfolioValue - todayGain)) * 100
        : 0.0;

    return PortfolioSnapshot(
      totalStockValue: totalStockValue,
      cashReserve: cashReserve,
      totalPortfolioValue: totalPortfolioValue,
      totalInvested: totalInvested,
      totalReturns: totalReturns,
      returnsPercent: returnsPercent,
      todayGain: todayGain,
      todayPercent: todayPercent,
      allHoldings: holdings,
      holdingCurrentPrices: holdingCurrentPrices,
      holdingCurrentValues: holdingCurrentValues,
      sectorBreakdown: sectorBreakdown,
    );
  }
}
