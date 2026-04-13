import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/widgets/chatbot/ai_chat_bubble.dart';
import 'package:edu_app_flutter/views/widgets/chatbot/user_chat_bubble.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  const _ChatMessage({required this.sender, required this.text});

  final _MessageSender sender;
  final String text;
}

enum _MessageSender { ai, user }

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      sender: _MessageSender.ai,
      text:
          'Chao ban, toi la tro ly hoc tap EduTeacher. Toi co the giup gi cho ban hom nay?',
    ),
    const _ChatMessage(
      sender: _MessageSender.user,
      text: 'Hay giup minh phan tich ket qua hoc tap ky vua roi.',
    ),
    const _ChatMessage(
      sender: _MessageSender.ai,
      text:
          'Dua tren diem so cua ban, mon Toan va Ly dang co su tien bo ro ret. Tuy nhien, mon Tieng Anh can cai thien them ve phan tu vung.',
    ),
  ];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final userAvatar = (AuthSession.instance.user?.avatar ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                children: [
                  ..._messages.map(
                    (message) => message.sender == _MessageSender.ai
                        ? AiChatBubble(message: message.text)
                        : UserChatBubble(
                            message: message.text,
                            avatar: userAvatar,
                          ),
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionChips(),
                ],
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return OcrFlowHeader(
      title: 'Chatbot',
      subtitle: 'Tro ly hoc tap AI',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
    );
  }

  Widget _buildSuggestionChips() {
    const suggestions = <String>[
      'Phan tich hoc luc',
      'Goi y lo trinh hoc',
      'Tai lieu on tap',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: suggestions
          .map(
            (text) => OutlinedButton(
              onPressed: () {
                _messageController.text = text;
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCAD5F7)),
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: AppFontSizes.dashboardBody,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                backgroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: Text(text),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Nhap tin nhan...',
                  hintStyle: TextStyle(color: AppColors.inputHint),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: _handleSend,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x401337EC),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(sender: _MessageSender.user, text: text));
      _messages.add(
        const _ChatMessage(
          sender: _MessageSender.ai,
          text:
              'Minh da nhan cau hoi. Ban co the gui them thong tin diem tung mon de minh phan tich chi tiet hon.',
        ),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }
}
