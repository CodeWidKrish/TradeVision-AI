import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
      : super([
          ChatMessage(
            text:
                'Hi! I am your TradeVision AI assistant. Ask me anything about stocks or the market — I will explain it in simple language!',
            isUser: false,
            time: _nowIST(),
          ),
        ]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearChat() {
    state = [state.first]; // keep welcome message only
  }

  static String _nowIST() {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final h = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
