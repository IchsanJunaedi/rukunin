import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiState({this.messages = const [], this.isLoading = false, this.error});

  AiState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiAssistantNotifier extends Notifier<AiState> {
  @override
  AiState build() {
    return AiState(messages: [
      ChatMessage(
        text: 'Halo! Saya Rukunin AI 🤖\nSaya bisa membantu Anda menganalisis data keuangan RT/RW. Silakan tanyakan apa saja!',
        isUser: false,
        timestamp: DateTime.now(),
      )
    ]);
  }

  Future<void> sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    // Tambahkan pesan user
    final userMsg = ChatMessage(text: question, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true, error: null);

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'];

      if (communityId == null) throw Exception('Community ID tidak ditemukan');

      final now = DateTime.now();
      final response = await client.functions.invoke('ai-assistant', body: {
        'question': question,
        'community_id': communityId,
        'month': now.month,
        'year': now.year,
      });

      if (response.data == null) throw Exception('Respons kosong dari server');

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) throw Exception(data['error'] ?? 'Terjadi kesalahan');

      final aiMsg = ChatMessage(
        text: data['answer'] as String,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, aiMsg], isLoading: false);
    } catch (e) {
      final errMsg = ChatMessage(
        text: 'Maaf, terjadi kesalahan: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errMsg], isLoading: false, error: e.toString());
    }
  }

  void clearChat() {
    state = AiState(messages: [
      ChatMessage(
        text: 'Halo! Saya Rukunin AI 🤖\nSaya bisa membantu Anda menganalisis data keuangan RT/RW. Silakan tanyakan apa saja!',
        isUser: false,
        timestamp: DateTime.now(),
      )
    ]);
  }
}

final aiAssistantProvider = NotifierProvider<AiAssistantNotifier, AiState>(AiAssistantNotifier.new);
