import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/chatbot_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
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
  final ChatbotService _chatbotService = ChatbotService();
  final OcrService _ocrService = OcrService();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  List<OcrAllStudentDataItem>? _cachedStudents;
  String? _conversationId;

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
              child: _messages.isEmpty && !_isSending
                  ? _buildEmptyStateDecor()
                  : ListView(
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
                        if (_isSending)
                          const AiChatBubble(
                            message: 'Dang phan tich du lieu hoc tap...',
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

  Widget _buildEmptyStateDecor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.heroPrimary, AppColors.heroSecondary],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331337EC),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.chatbot,
                  color: AppColors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chao ban, toi co the giup gi duoc cho ban?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dat cau hoi ve ket qua hoc tap de AI phan tich va goi y cho ban.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardBody,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 18),
              _buildSuggestionChips(),
            ],
          ),
        ),
      ),
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
                onSubmitted: (_) {
                  if (!_isSending) {
                    _handleSend();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: _isSending ? null : _handleSend,
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

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(sender: _MessageSender.user, text: text));
      _messageController.clear();
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final students = await _getStudentsForChatbot();
      final response = await _chatbotService.askChatbot(
        question: text,
        students: students,
        conversationId: _conversationId,
      );

      final answer = response.answer.trim();

      if (!mounted) {
        return;
      }

      setState(() {
        if (answer.isNotEmpty) {
          _messages.add(_ChatMessage(sender: _MessageSender.ai, text: answer));
        }
        final conversationId = response.conversationId.trim();
        if (conversationId.isNotEmpty) {
          _conversationId = conversationId;
        }
      });
    } catch (e) {
      final fallback = e is ApiException
          ? e.message
          : 'Chatbot dang ban. Vui long thu lai sau it phut.';

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(_ChatMessage(sender: _MessageSender.ai, text: fallback));
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;
      });

      _scrollToBottom();
    }
  }

  Future<List<OcrAllStudentDataItem>> _getStudentsForChatbot() async {
    if (_cachedStudents != null) {
      return _cachedStudents!;
    }

    try {
      final response = await _ocrService.getAllStudentData();
      _cachedStudents = response.students;
    } catch (_) {
      _cachedStudents = const <OcrAllStudentDataItem>[];
    }

    return _cachedStudents!;
  }

  void _scrollToBottom() {
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
