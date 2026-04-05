import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../providers/ai_assistant_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickActions = [
    'Ringkasan keuangan bulan ini',
    'Siapa saja warga yang belum bayar?',
    'Berapa collection rate bulan ini?',
    'Apa saja pengeluaran terbesar?',
    'Buat teks pengumuman tagihan',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(aiAssistantProvider);

    // Auto scroll when new messages arrive
    ref.listen(aiAssistantProvider, (prev, next) {
      if (next.messages.length != prev?.messages.length || next.isLoading != prev?.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [RukuninColors.brandGreen, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rukunin AI', style: RukuninFonts.pjs(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Didukung Groq Llama3', style: RukuninFonts.pjs(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus riwayat chat',
            onPressed: () => ref.read(aiAssistantProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  return _buildTypingIndicator(isDark);
                }
                final msg = state.messages[index];
                return _buildChatBubble(msg, isDark);
              },
            ),
          ),

          // Quick actions
          if (state.messages.length <= 1)
            _buildQuickActions(isDark),

          // Input
          _buildInputBar(state, isDark),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [RukuninColors.brandGreen, Colors.purple.shade400]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: RukuninFonts.pjs(
                      color: msg.isUser ? Colors.white : (isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: RukuninFonts.pjs(
                      fontSize: 10,
                      color: msg.isUser ? Colors.white60 : (isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [RukuninColors.brandGreen, Colors.purple.shade400]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(150),
                const SizedBox(width: 4),
                _buildDot(300),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Transform.translate(
          offset: Offset(0, -4 * value),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Container(
      color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pertanyaan Cepat:', style: RukuninFonts.pjs(
            fontSize: 12,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _quickActions.map((q) => GestureDetector(
              onTap: () => _sendMessage(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: RukuninColors.brandGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Text(q, style: RukuninFonts.pjs(fontSize: 12, color: RukuninColors.brandGreen)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: RukuninFonts.pjs(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tanya sesuatu tentang keuangan RW...',
                  hintStyle: RukuninFonts.pjs(
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: state.isLoading ? null : () => _sendMessage(_controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: state.isLoading
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                      : LinearGradient(colors: [RukuninColors.brandGreen, Colors.purple.shade500]),
                  shape: BoxShape.circle,
                ),
                child: state.isLoading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
