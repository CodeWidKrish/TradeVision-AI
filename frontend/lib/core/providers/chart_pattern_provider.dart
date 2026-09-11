import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../models/ohlc_point.dart';

/// Global provider ensuring that the user's selected chart pattern (Line vs Candlestick)
/// is 100% uniform across every single stock and screen in the entire app.
final chartPatternProvider = StateNotifierProvider<ChartPatternNotifier, ChartType>((ref) {
  final saved = StorageService.getChartType();
  final initialType = saved == 'line' ? ChartType.line : ChartType.candlestick;
  return ChartPatternNotifier(initialType);
});

class ChartPatternNotifier extends StateNotifier<ChartType> {
  ChartPatternNotifier([ChartType initialType = ChartType.candlestick]) : super(initialType);

  Future<void> setChartType(ChartType type) async {
    state = type;
    await StorageService.setChartType(type.name);
  }

  Future<void> togglePattern() async {
    final next = state == ChartType.candlestick ? ChartType.line : ChartType.candlestick;
    await setChartType(next);
  }

  bool get isCandlestick => state == ChartType.candlestick;
  bool get isLine => state == ChartType.line;
}
