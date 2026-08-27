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
import '../widgets/ai_settings_dialog.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'كم صافي أرباح الشهر الحالي وإجمالي المبيعات؟',
    'اعطني ملخص مؤشرات الأداء المالي وأرصدة الحسابات',
    'أنشئ سند قبض بمبلغ 1500 ريال نقداً',
    'ما هي الأصناف والكميات المتاحة في المستودع؟',
    'اعطني تقرير أعمار ديون العملاء',
  ];

  @override
  void dispose() {
    _inputController.dispose();
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

  void _handleSend([String? textToSend]) {
    final prompt = textToSend ?? _inputController.text.trim();
    if (prompt.isEmpty) return;

    _inputController.clear();
    context.read<AiAssistantProvider>().sendMessage(prompt);
    _scrollToBottom();
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
        title: 'المساعد المحاسبي الذكي (AI Agent)',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.accent.withOpacity(isDark ? 0.2 : 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'الرجاء إدخال مفتاح API (OpenAI, Gemini, أو Groq) لبدء التحدث وتنفيذ المهام المحاسبية.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _showSettings,
                    child: const Text('إدخال المفتاح', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.sender == MessageSender.user;

                return Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.darkCard
                                  : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          border: isUser ? null : Border.all(color: AppColors.lightBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.isLoading) ...[
                              Row(
                                children: [
                                  const AppLoader(size: 16, strokeWidth: 2),
                                  const SizedBox(width: 10),
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              SelectableText(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isUser
                                      ? Colors.white
                                      : isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],

                            // Render Executed Real ERP Actions if any
                            if (msg.executedActions != null && msg.executedActions!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 16),
                              const Row(
                                children: [
                                  Icon(Icons.task_alt, color: AppColors.secondary, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'المهام المحاسبية المنفذة بالنظام:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...msg.executedActions!.map((action) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check, color: AppColors.secondaryDark, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'أداة: ${action.toolName} - تم التنفيذ والترحيل بنجاح',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        child: const Icon(Icons.person, color: AppColors.secondaryDark, size: 18),
                      ),
                    ],
                  ],
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

          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: AppColors.lightBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'اطلب من المساعد الذكي أي عملية أو استعلام مالي...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.lightBorder),
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
