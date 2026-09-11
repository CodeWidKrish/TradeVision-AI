import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradevision_ai/widgets/ai_confidence_gauge.dart';
import 'package:tradevision_ai/widgets/ticker_flash_price.dart';
import 'package:tradevision_ai/widgets/chart_type_selector.dart';
import 'package:tradevision_ai/core/data/stock_data.dart';
import 'package:tradevision_ai/core/models/ohlc_point.dart';
import 'package:tradevision_ai/core/providers/chart_pattern_provider.dart';
import 'package:tradevision_ai/widgets/ticker_logo.dart';
import 'package:tradevision_ai/widgets/swipe_to_execute_button.dart';
import 'package:tradevision_ai/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('AiConfidenceGauge renders score and label correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiConfidenceGauge(score: 88.5, label: 'AI Confidence'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('89%'), findsOneWidget);
    expect(find.text('AI Confidence'), findsOneWidget);
  });

  testWidgets('TickerFlashPrice renders price correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TickerFlashPrice(price: 2896.25, formattedPrice: '₹2,896.25'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('₹2,896.25'), findsOneWidget);
  });

  test('Every stock in repository produces valid OHLC points for each timeframe', () {
    final periods = ['1D', '1W', '1M', '3M', '1Y', '5Y', 'MAX'];
    for (final stock in StockRepository.stocks) {
      for (final period in periods) {
        final ohlc = stock.getOhlcPoints(period);
        expect(ohlc.isNotEmpty, isTrue, reason: '${stock.ticker} should have data for $period');
        final sanitized = OhlcSanitizer.sanitize(ohlc);
        expect(sanitized.data.isNotEmpty, isTrue, reason: '${stock.ticker} data should be valid');
        for (final pt in sanitized.data) {
          expect(pt.high >= pt.low, isTrue);
          expect(pt.high >= pt.open, isTrue);
          expect(pt.high >= pt.close, isTrue);
          expect(pt.low <= pt.open, isTrue);
          expect(pt.low <= pt.close, isTrue);
        }
      }
    }
  });

  testWidgets('ChartHeaderRow renders periods and toggles between line and candlestick', (WidgetTester tester) async {
    ChartType currentType = ChartType.line;
    String currentPeriod = '1D';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ChartHeaderRow(
                  periods: const ['1D', '1W', '1M', '3M', '6M', '1Y'],
                  selectedPeriod: currentPeriod,
                  onPeriodChanged: (p) => setState(() => currentPeriod = p),
                  selectedType: currentType,
                  onTypeChanged: (t) => setState(() => currentType = t),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1D'), findsOneWidget);
    expect(find.text('1W'), findsOneWidget);
    expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.candlestick_chart_rounded), findsOneWidget);

    // Tap candlestick icon
    await tester.tap(find.byIcon(Icons.candlestick_chart_rounded));
    await tester.pump();

    expect(currentType, equals(ChartType.candlestick));
  });

  testWidgets('TickerLogo renders successfully for all stocks', (WidgetTester tester) async {
    for (final s in StockRepository.stocks) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerLogo(ticker: s.ticker, size: 40),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TickerLogo), findsOneWidget);
    }
  });

  testWidgets('SwipeToExecuteButton renders and triggers onConfirmed', (WidgetTester tester) async {
    bool confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SwipeToExecuteButton(
                isBuy: true,
                stockTicker: 'RELIANCE',
                priceFormatted: '₹2,886.76',
                quantity: 2,
                onConfirmed: () => confirmed = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SWIPE TO BUY • ₹2,886.76'), findsOneWidget);

    // Perform drag gesture across the button
    await tester.drag(find.byIcon(Icons.trending_up_rounded), const Offset(260, 0));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('BOUGHT 2 RELIANCE • EXECUTED'), findsOneWidget);
  });

  testWidgets('AppBottomNav renders all tabs and triggers onTabSelected', (WidgetTester tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: selectedIndex,
            onTabSelected: (idx) => selectedIndex = idx,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);

    await tester.tap(find.text('Market'));
    await tester.pump();
    expect(selectedIndex, equals(1));

    await tester.tap(find.text('AI'));
    await tester.pump();
    expect(selectedIndex, equals(3));
  });
}
