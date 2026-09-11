import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';

final authStateProvider = FutureProvider<bool>((ref) async {
  return StorageService.getIsLoggedIn();
});

final isLoggedInProvider = StateProvider<bool>((ref) => false);

class AuthService {
  static Future<void> login(WidgetRef ref) async {
    await StorageService.setLoggedIn(true);
    ref.read(isLoggedInProvider.notifier).state = true;
  }

  static Future<void> logout(WidgetRef ref) async {
    await StorageService.setLoggedIn(false);
    ref.read(isLoggedInProvider.notifier).state = false;
  }
}
