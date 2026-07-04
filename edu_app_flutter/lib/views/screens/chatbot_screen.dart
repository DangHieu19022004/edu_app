import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/chatbot_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/widgets/chatbot/ai_chat_bubble.dart';
import 'package:edu_app_flutter/views/widgets/chatbot/ai_typing_indicator.dart';
import 'package:edu_app_flutter/views/widgets/chatbot/user_chat_bubble.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';


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

enum _ChatbotMode { generalConsultation, resultAnalysis }

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatbotService _chatbotService = ChatbotService();
  final OcrService _ocrService = OcrService();
  final Map<_ChatbotMode, List<_ChatMessage>> _messagesByMode =
      <_ChatbotMode, List<_ChatMessage>>{
        _ChatbotMode.generalConsultation: <_ChatMessage>[],
        _ChatbotMode.resultAnalysis: <_ChatMessage>[],
      };
  final ScrollController _scrollController = ScrollController();
  List<OcrAllStudentDataItem>? _cachedStudents;
  _ChatbotMode _activeMode = _ChatbotMode.generalConsultation;
  _ChatbotMode? _sendingMode;

  List<_ChatMessage> get _activeMessages => _messagesByMode[_activeMode]!;

  bool get _isSending => _sendingMode != null;

  bool get _isSendingActiveMode => _sendingMode == _activeMode;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAvatar = (AuthSession.instance.user?.avatar ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildModeTabs(),
              Expanded(
                child: _activeMessages.isEmpty && !_isSendingActiveMode
                    ? _buildEmptyStateDecor()
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        children: [
                          ..._activeMessages.map(
                            (message) => message.sender == _MessageSender.ai
                                ? AiChatBubble(message: message.text)
                                : UserChatBubble(
                                    message: message.text,
                                    avatar: userAvatar,
                                  ),
                          ),
                          if (_isSendingActiveMode) const AiTypingIndicator(),
                        ],
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return OcrFlowHeader(
      title: 'Chatbot',
      subtitle: 'Trợ lý học tập AI',
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

  Widget _buildModeTabs() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModeTab(
                  mode: _ChatbotMode.generalConsultation,
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Tư vấn chung',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeTab(
                  mode: _ChatbotMode.resultAnalysis,
                  icon: Icons.insights_rounded,
                  label: 'Phân tích kết quả',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Container(
              key: ValueKey<_ChatbotMode>(_activeMode),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _activeMode == _ChatbotMode.generalConsultation
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.school_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeMode == _ChatbotMode.generalConsultation
                          ? 'Hỏi về phương pháp dạy học, soạn bài - Chế độ tiết kiệm'
                          : 'Hỏi về điểm số, gợi ý hỗ trợ học sinh - Chế độ phân tích',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required _ChatbotMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = mode == _activeMode;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (isSelected) {
          return;
        }

        _dismissKeyboard();
        setState(() {
          _activeMode = mode;
        });
        _scrollToBottom();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F4FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.white : AppColors.subtitle,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.white : AppColors.label,
                ),
              ),
            ),
          ],
        ),
      ),
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
                'Chào bạn, tôi có thể giúp gì cho bạn?',
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
                'Đặt câu hỏi về kết quả học tập để AI phân tích và gợi ý cho bạn.',
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
      AppTexts.chatbotHint1,
      AppTexts.chatbotHint2,
      AppTexts.chatbotHint3,
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
                  hintText: AppTexts.chatbotInputHint,
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

    final sendingMode = _activeMode;
    final messages = _messagesByMode[sendingMode]!;

    setState(() {
      messages.add(_ChatMessage(sender: _MessageSender.user, text: text));
      _messageController.clear();
      _sendingMode = sendingMode;
    });

    _scrollToBottom();

    try {
      final students = sendingMode == _ChatbotMode.resultAnalysis
          ? await _getStudentsForChatbot()
          : const <OcrAllStudentDataItem>[];
      final response = await _chatbotService.askChatbot(
        question: text,
        students: students,
        contextMode: sendingMode == _ChatbotMode.resultAnalysis
            ? 'result_analysis'
            : 'general',
      );

      final answer = response.answer.trim();

      if (!mounted) {
        return;
      }

      setState(() {
        if (answer.isNotEmpty) {
          messages.add(_ChatMessage(sender: _MessageSender.ai, text: answer));
        }
      });
    } catch (e) {
      final fallback = e is ApiException
          ? e.message
          : AppTexts.chatbotError;

      if (!mounted) {
        return;
      }

      setState(() {
        messages.add(_ChatMessage(sender: _MessageSender.ai, text: fallback));
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _sendingMode = null;
      });

      _scrollToBottom();
    }
  }

  Future<List<OcrAllStudentDataItem>> _getStudentsForChatbot() async {
    if (_cachedStudents != null) {
      return _cachedStudents!;
    }

    try {
      final response = await _ocrService.getAllStudentDataSilently();
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

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }
}
