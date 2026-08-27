import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/ai_message.dart';
import '../providers/ai_assistant_provider.dart';
import '../services/ai_service.dart';
import '../services/ai_voice_service.dart';
import '../widgets/ai_settings_dialog.dart';
import 'ai_voice_call_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isVoiceRecording = false;

  final List<String> _suggestedPrompts = [
    'أنشئ سند قبض بمبلغ 1500 ريال نقداً',
    'ما هي الأصناف والكميات المتاحة في المستودع؟',
    'استعرض قائمة العملاء والموردين',
    'كم صافي أرباح الشهر الحالي وإجمالي المبيعات؟',
    'استعرض شجرة ودليل الحسابات المالية',
    'استعرض حافظة الشيكات وحالتها',
    'أضف عميل جديد اسمه شركة الأمل للتجارة',
    'أضف صنف جديد اسمه شاشة سامسونج 4K',
    'احذف السند رقم 1',
    'حصل الشيك رقم 1',
    'حول عرض السعر رقم 1 إلى فاتورة',
    'اهلك الأصل رقم 1',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    AiVoiceService.stopListening();
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

  void _handleSend([String? textToSend]) {
    final prompt = textToSend ?? _inputController.text.trim();
    if (prompt.isEmpty) return;

    _inputController.clear();
    context.read<AiAssistantProvider>().sendMessage(prompt);
    _scrollToBottom();
  }

  void _toggleVoiceInput() async {
    if (_isVoiceRecording) {
      await AiVoiceService.stopListening();
      setState(() {
        _isVoiceRecording = false;
      });
      if (_inputController.text.trim().isNotEmpty) {
        _handleSend();
      }
    } else {
      final ok = await AiVoiceService.initialize();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر الوصول للمايكروفون. يرجى التأكد من الصلاحيات.')),
          );
        }
        return;
      }

      setState(() {
        _isVoiceRecording = true;
      });

      await AiVoiceService.startListening(
        onResult: (words, isFinal) {
          if (mounted) {
            setState(() {
              _inputController.text = words;
            });
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isVoiceRecording) {
              setState(() {
                _isVoiceRecording = false;
              });
            }
          }
        },
      );
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (_) => const AiSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = context.watch<AiAssistantProvider>();
    final messages = ai.messages;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'غباء | المساعد المحاسبي الذكي',
        actions: [
          // Active Provider Badge & Settings
          InkWell(
            onTap: _showSettings,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: ai.hasValidApiKey
                    ? AppColors.secondary.withOpacity(0.15)
                    : AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ai.hasValidApiKey ? AppColors.secondary : AppColors.danger,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ai.hasValidApiKey ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    size: 14,
                    color: ai.hasValidApiKey ? AppColors.secondaryDark : AppColors.danger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ai.selectedProvider == AiProviderType.openai
                        ? 'ChatGPT'
                        : ai.selectedProvider == AiProviderType.gemini
                            ? 'Gemini'
                            : 'Groq',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ai.hasValidApiKey ? AppColors.secondaryDark : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Live Voice Call Action Button (📞)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.secondary, size: 20),
            ),
            tooltip: 'بدء اتصال صوتي مباشر مع المساعد',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiVoiceCallScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'إعدادات مفاتيح AI',
            onPressed: _showSettings,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'مسح المحادثة',
            onPressed: () => ai.clearChat(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner if No API Key is set
          if (!ai.hasValidApiKey)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.danger.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ملاحظة: يمكنك إدخال مفتاحك الخاص بالضغط على الإعدادات ⚙️ أعلى الشاشة لتمكين النماذج الذكية المتقدمة.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: _showSettings,
                    child: const Text('إدخال المفتاح', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('لا توجد رسائل سابقة'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.sender == MessageSender.user;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkSurface : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: AppColors.lightBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (msg.isLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        child: AppLoader(size: 20),
                                      )
                                    else
                                      SelectableText(
                                        msg.text + (msg.isStreaming ? ' ▍' : ''),
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    if (msg.executedActions != null && msg.executedActions!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (isDark ? Colors.black26 : Colors.grey.shade50),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: const [
                                                Icon(Icons.check_circle_outline, size: 14, color: AppColors.secondary),
                                                SizedBox(width: 4),
                                                Text(
                                                  'المهام المحاسبية المنفذة بالنظام:',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ...msg.executedActions!.map((action) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      action.isSuccess ? Icons.done : Icons.error_outline,
                                                      size: 12,
                                                      color: action.isSuccess ? Colors.green : Colors.red,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        'أداة: ${action.toolName} - ${action.isSuccess ? "تم التنفيذ والترحيل بنجاح" : "تعذر التنفيذ"}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? Colors.white70 : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatTime(msg.timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isUser
                                            ? Colors.white70
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, color: AppColors.secondaryDark, size: 20),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Suggested Prompts Carousel
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),

          // Input Bar with Mic & Send
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: AppColors.lightBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Microphone Speech Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isVoiceRecording ? Colors.redAccent : AppColors.secondary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isVoiceRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isVoiceRecording ? Colors.white : AppColors.secondaryDark,
                      ),
                      tooltip: _isVoiceRecording ? 'إيقاف التسجيل الصوتي' : 'تحدث صوتياً',
                      onPressed: _toggleVoiceInput,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: _isVoiceRecording ? '🎙️ جاري الاستماع إلى صوتك...' : 'اطلب من المساعد الذكي أي عملية أو استعلام مالي...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: _isVoiceRecording ? Colors.redAccent : AppColors.lightBorder),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: ai.isLoading ? null : () => _handleSend(),
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
}
