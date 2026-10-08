import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// ======================================================
// SOKR Assistant: chat bot b Gemini
// el app bey3t el rasayel le Supabase Edge Function esmha "chat"
// w el function di heya elly betkalem Gemini (el API key msh gowa el app)
// ======================================================

class ChatMessage {
  final String role; // 'user' aw 'model'
  final String text;
  const ChatMessage(this.role, this.text);
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _waiting = false;

  // as2ela gahza 3shan el user ybd2 bsor3a
  static const _suggestions = [
    'Is my blood sugar reading normal?',
    'What exercise is good for diabetes?',
    'Suggest a healthy breakfast',
    'eh a7san wa2t a2es el sokkar?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // hena bnb3t el ras2el lel bot w nstanna el rad
  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _waiting) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage('user', text));
      _waiting = true;
    });
    _scrollDown();

    try {
      final res = await supabase.functions.invoke('chat', body: {
        'messages': [for (final m in _messages) {'role': m.role, 'text': m.text}],
      });
      final data = res.data as Map<String, dynamic>?;
      final reply = (data?['reply'] ?? data?['error'] ?? 'Sorry, something went wrong.').toString();
      setState(() => _messages.add(ChatMessage('model', reply)));
    } catch (e) {
      setState(() => _messages.add(const ChatMessage(
          'model', 'The assistant is not available right now. Please try again in a moment.')));
    } finally {
      if (mounted) setState(() => _waiting = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(iconOnly: true, height: 30),
            SizedBox(width: 8),
            Text('SOKR Assistant'),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              onPressed: () => setState(_messages.clear),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildMessages(),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: AppLogo(iconOnly: true, height: 80)),
        const SizedBox(height: 12),
        const Text('Hi! I am SOKR Assistant',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Ask me about your health, sugar levels, exercise, food or medicines.\n'
            'You can write in Arabic, Franco or English.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        const DisclaimerCard(),
        const SizedBox(height: 16),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _send(s),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length + (_waiting ? 1 : 0),
      itemBuilder: (context, i) {
        // "typing..." w el bot by-fakar
        if (i == _messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        final m = _messages[i];
        final isUser = m.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : Colors.white,
              boxShadow: isUser ? null : softShadow,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: SelectableText(
              m.text,
              style: TextStyle(color: isUser ? Colors.white : AppColors.text, height: 1.4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'Ask about your health...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _waiting ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
