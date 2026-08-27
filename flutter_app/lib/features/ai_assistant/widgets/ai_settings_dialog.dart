import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/ai_assistant_provider.dart';
import '../services/ai_service.dart';

class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late AiProviderType _provider;
  final _openAiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _groqKeyController = TextEditingController();

  final _openAiModelController = TextEditingController();
  final _geminiModelController = TextEditingController();
  final _groqModelController = TextEditingController();

  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<AiAssistantProvider>();
    _provider = p.selectedProvider;
    _openAiKeyController.text = p.openAiKey;
    _geminiKeyController.text = p.geminiKey;
    _groqKeyController.text = p.groqKey;

    _openAiModelController.text = p.currentModel;
    _geminiModelController.text = p.geminiKey.isNotEmpty ? p.currentModel : 'gemini-1.5-flash';
    _groqModelController.text = p.groqKey.isNotEmpty ? p.currentModel : 'llama-3.3-70b-versatile';
  }

  @override
  void dispose() {
    _openAiKeyController.dispose();
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    _openAiModelController.dispose();
    _geminiModelController.dispose();
    _groqModelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    await context.read<AiAssistantProvider>().saveApiKeys(
      openAiKey: _openAiKeyController.text,
      geminiKey: _geminiKeyController.text,
      groqKey: _groqKeyController.text,
      openAiModel: _openAiModelController.text.isNotEmpty ? _openAiModelController.text : 'gpt-4o-mini',
      geminiModel: _geminiModelController.text.isNotEmpty ? _geminiModelController.text : 'gemini-1.5-flash',
      groqModel: _groqModelController.text.isNotEmpty ? _groqModelController.text : 'llama-3.3-70b-versatile',
      provider: _provider,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ مفتاح وإعدادات الذكاء الاصطناعي بنجاح'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary),
          SizedBox(width: 8),
          Text('إعدادات الذكاء الاصطناعي (AI Keys)'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر مزود الذكاء الاصطناعي المفضل لديك:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Provider Choice Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('ChatGPT (OpenAI)'),
                    selected: _provider == AiProviderType.openai,
                    onSelected: (_) => setState(() => _provider = AiProviderType.openai),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Google Gemini'),
                    selected: _provider == AiProviderType.gemini,
                    onSelected: (_) => setState(() => _provider = AiProviderType.gemini),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Groq (سريع جداً)'),
                    selected: _provider == AiProviderType.groq,
                    onSelected: (_) => setState(() => _provider = AiProviderType.groq),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Dynamic Fields depending on provider
              if (_provider == AiProviderType.openai) ...[
                CustomTextField(
                  controller: _openAiKeyController,
                  label: 'OpenAI API Key *',
                  hint: 'sk-proj-...',
                  prefixIcon: Icons.key_rounded,
                  obscureText: _obscureKey,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'].contains(_openAiModelController.text)
                      ? _openAiModelController.text
                      : 'gpt-4o-mini',
                  decoration: const InputDecoration(labelText: 'النموذج (Model)'),
                  items: const [
                    DropdownMenuItem(value: 'gpt-4o-mini', child: Text('GPT-4o Mini (سريع واقتصادي)')),
                    DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o (النموذج الأقوى)')),
                    DropdownMenuItem(value: 'gpt-4-turbo', child: Text('GPT-4 Turbo')),
                    DropdownMenuItem(value: 'gpt-3.5-turbo', child: Text('GPT-3.5 Turbo')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _openAiModelController.text = val);
                  },
                ),
              ] else if (_provider == AiProviderType.gemini) ...[
                CustomTextField(
                  controller: _geminiKeyController,
                  label: 'Google Gemini API Key *',
                  hint: 'AIzaSy...',
                  prefixIcon: Icons.key_rounded,
                  obscureText: _obscureKey,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'].contains(_geminiModelController.text)
                      ? _geminiModelController.text
                      : 'gemini-1.5-flash',
                  decoration: const InputDecoration(labelText: 'النموذج (Model)'),
                  items: const [
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash (سريع)')),
                    DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro (ذكي)')),
                    DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('Gemini 2.0 Flash')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _geminiModelController.text = val);
                  },
                ),
              ] else if (_provider == AiProviderType.groq) ...[
                CustomTextField(
                  controller: _groqKeyController,
                  label: 'Groq API Key *',
                  hint: 'gsk_...',
                  prefixIcon: Icons.key_rounded,
                  obscureText: _obscureKey,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'mixtral-8x7b-32768'].contains(_groqModelController.text)
                      ? _groqModelController.text
                      : 'llama-3.3-70b-versatile',
                  decoration: const InputDecoration(labelText: 'النموذج (Model)'),
                  items: const [
                    DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B Versatile')),
                    DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B Instant')),
                    DropdownMenuItem(value: 'mixtral-8x7b-32768', child: Text('Mixtral 8x7B')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _groqModelController.text = val);
                  },
                ),
              ],
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يتم حفظ مفاتيح API محلياً على جهازك فقط ولا يتم مشاركتها أبداً.',
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('حفظ الإعدادات'),
        ),
      ],
    );
  }
}
