import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super(StorageService.getWatchlistSymbols());

  bool isSaved(String symbol) {
    final sym = symbol.toUpperCase();
    return state.contains(sym);
  }

  void toggleWatchlist(String symbol) {
    final sym = symbol.toUpperCase();
    if (state.contains(sym)) {
      state = state.where((s) => s != sym).toList();
    } else {
      state = [...state, sym];
    }
    StorageService.setWatchlistSymbols(state);
  }

  void addSymbol(String symbol) {
    final sym = symbol.toUpperCase();
    if (!state.contains(sym)) {
      state = [...state, sym];
      StorageService.setWatchlistSymbols(state);
    }
  }

  void removeSymbol(String symbol) {
    final sym = symbol.toUpperCase();
    if (state.contains(sym)) {
      state = state.where((s) => s != sym).toList();
      StorageService.setWatchlistSymbols(state);
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  return WatchlistNotifier();
});
