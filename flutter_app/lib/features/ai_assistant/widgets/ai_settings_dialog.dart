import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
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

  String _selectedOpenAiModel = 'gpt-4o-mini';
  String _selectedGeminiModel = 'gemini-1.5-flash';
  String _selectedGroqModel = 'llama-3.1-8b-instant';

  List<String> _openAiModels = [];
  List<String> _geminiModels = [];
  List<String> _groqModels = [];

  bool _isLoadingModels = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<AiAssistantProvider>();
    _provider = p.selectedProvider;
    _openAiKeyController.text = p.openAiKey;
    _geminiKeyController.text = p.geminiKey;
    _groqKeyController.text = p.groqKey;

    _selectedOpenAiModel = p.openAiKey.isNotEmpty ? p.currentModel : 'gpt-4o-mini';
    _selectedGeminiModel = p.geminiKey.isNotEmpty ? p.currentModel : 'gemini-1.5-flash';
    _selectedGroqModel = p.groqKey.isNotEmpty ? p.currentModel : 'llama-3.1-8b-instant';

    _openAiModels = List.from(AiService.getDefaultModels(AiProviderType.openai));
    _geminiModels = List.from(AiService.getDefaultModels(AiProviderType.gemini));
    _groqModels = List.from(AiService.getDefaultModels(AiProviderType.groq));

    _fetchLiveModels();
  }

  @override
  void dispose() {
    _openAiKeyController.dispose();
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveModels() async {
    String currentKey = '';
    if (_provider == AiProviderType.groq) currentKey = _groqKeyController.text;
    if (_provider == AiProviderType.openai) currentKey = _openAiKeyController.text;
    if (_provider == AiProviderType.gemini) currentKey = _geminiKeyController.text;

    if (currentKey.trim().isEmpty) return;

    setState(() => _isLoadingModels = true);
    final models = await AiService.fetchAvailableModels(_provider, currentKey);

    if (mounted) {
      setState(() {
        _isLoadingModels = false;
        if (_provider == AiProviderType.groq) {
          _groqModels = models;
          if (!_groqModels.contains(_selectedGroqModel)) {
            _selectedGroqModel = _groqModels.first;
          }
        } else if (_provider == AiProviderType.openai) {
          _openAiModels = models;
          if (!_openAiModels.contains(_selectedOpenAiModel)) {
            _selectedOpenAiModel = _openAiModels.first;
          }
        } else if (_provider == AiProviderType.gemini) {
          _geminiModels = models;
          if (!_geminiModels.contains(_selectedGeminiModel)) {
            _selectedGeminiModel = _geminiModels.first;
          }
        }
      });
    }
  }

  Future<void> _handleSave() async {
    await context.read<AiAssistantProvider>().saveApiKeys(
      openAiKey: _openAiKeyController.text,
      geminiKey: _geminiKeyController.text,
      groqKey: _groqKeyController.text,
      openAiModel: _selectedOpenAiModel,
      geminiModel: _selectedGeminiModel,
      groqModel: _selectedGroqModel,
      provider: _provider,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ مفتاح وإعدادات النموذج بنجاح'),
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
          Text('إعدادات الذكاء الاصطناعي والنماذج المتاحة'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر مزود الذكاء الاصطناعي:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Provider Choice Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Groq (سريع جداً ومجاني)'),
                    selected: _provider == AiProviderType.groq,
                    onSelected: (_) {
                      setState(() => _provider = AiProviderType.groq);
                      _fetchLiveModels();
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('ChatGPT (OpenAI)'),
                    selected: _provider == AiProviderType.openai,
                    onSelected: (_) {
                      setState(() => _provider = AiProviderType.openai);
                      _fetchLiveModels();
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Google Gemini'),
                    selected: _provider == AiProviderType.gemini,
                    onSelected: (_) {
                      setState(() => _provider = AiProviderType.gemini);
                      _fetchLiveModels();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Dynamic Input Fields depending on provider
              if (_provider == AiProviderType.groq) ...[
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
                  onChanged: (_) => _fetchLiveModels(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _groqModels.contains(_selectedGroqModel) ? _selectedGroqModel : _groqModels.first,
                        decoration: InputDecoration(
                          labelText: 'النموذج المتاح (Model)',
                          suffixIcon: _isLoadingModels
                              ? const Padding(padding: EdgeInsets.all(12), child: AppLoader(size: 14))
                              : null,
                        ),
                        isExpanded: true,
                        items: _groqModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGroqModel = val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'تحديث النماذج المتاحة من حسابك',
                      onPressed: _fetchLiveModels,
                    ),
                  ],
                ),
              ] else if (_provider == AiProviderType.openai) ...[
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
                  onChanged: (_) => _fetchLiveModels(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _openAiModels.contains(_selectedOpenAiModel) ? _selectedOpenAiModel : _openAiModels.first,
                        decoration: InputDecoration(
                          labelText: 'النموذج المتاح (Model)',
                          suffixIcon: _isLoadingModels
                              ? const Padding(padding: EdgeInsets.all(12), child: AppLoader(size: 14))
                              : null,
                        ),
                        isExpanded: true,
                        items: _openAiModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedOpenAiModel = val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'تحديث النماذج المتاحة',
                      onPressed: _fetchLiveModels,
                    ),
                  ],
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
                  onChanged: (_) => _fetchLiveModels(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _geminiModels.contains(_selectedGeminiModel) ? _selectedGeminiModel : _geminiModels.first,
                        decoration: InputDecoration(
                          labelText: 'النموذج المتاح (Model)',
                          suffixIcon: _isLoadingModels
                              ? const Padding(padding: EdgeInsets.all(12), child: AppLoader(size: 14))
                              : null,
                        ),
                        isExpanded: true,
                        items: _geminiModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGeminiModel = val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'تحديث النماذج المتاحة',
                      onPressed: _fetchLiveModels,
                    ),
                  ],
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
                        'يتم جلب النماذج المتاحة تلقائياً وفقاً لمفتاحك، وحفظ المفاتيح محلياً على جهازك بأمان.',
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
          child: const Text('حفظ واختيار النموذج'),
        ),
      ],
    );
  }
}
