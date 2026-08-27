import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_message.dart';
import '../services/ai_service.dart';

class AiAssistantProvider extends ChangeNotifier {
  final List<AiMessage> _messages = [];
  bool _isLoading = false;

  AiProviderType _selectedProvider = AiProviderType.openai;
  String _openAiKey = '';
  String _geminiKey = '';
  String _groqKey = '';

  String _openAiModel = 'gpt-4o-mini';
  String _geminiModel = 'gemini-1.5-flash';
  String _groqModel = 'llama-3.3-70b-versatile';

  List<AiMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  AiProviderType get selectedProvider => _selectedProvider;

  String get openAiKey => _openAiKey;
  String get geminiKey => _geminiKey;
  String get groqKey => _groqKey;

  String get currentApiKey {
    switch (_selectedProvider) {
      case AiProviderType.openai:
        return _openAiKey;
      case AiProviderType.gemini:
        return _geminiKey;
      case AiProviderType.groq:
        return _groqKey;
    }
  }

  String get currentModel {
    switch (_selectedProvider) {
      case AiProviderType.openai:
        return _openAiModel;
      case AiProviderType.gemini:
        return _geminiModel;
      case AiProviderType.groq:
        return _groqModel;
    }
  }

  bool get hasValidApiKey => currentApiKey.trim().isNotEmpty;

  AiAssistantProvider() {
    _loadSettings();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        AiMessage(
          id: 'welcome',
          sender: MessageSender.assistant,
          text: 'مرحباً بك! أنا مساعد الأصيل الذكي 🤖✨.\nيمكنك سؤالي عن التقارير المالية والأرباح، أو توجيه أوامر لإنشاء فواتير، سندات قبض وصرف، قيود يومية، أو إضافة عملاء وأصناف فوراً.\n\nتفضل باختيار نموذجك المفضل (ChatGPT, Gemini, Groq) وأدخل مفتاح API الخاص بك من الإعدادات للبدء.',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerStr = prefs.getString('ai_provider');
    if (providerStr == 'gemini') {
      _selectedProvider = AiProviderType.gemini;
    } else if (providerStr == 'groq') {
      _selectedProvider = AiProviderType.groq;
    } else {
      _selectedProvider = AiProviderType.openai;
    }

    _openAiKey = prefs.getString('ai_openai_key') ?? '';
    _geminiKey = prefs.getString('ai_gemini_key') ?? '';
    _groqKey = prefs.getString('ai_groq_key') ?? '';

    _openAiModel = prefs.getString('ai_openai_model') ?? 'gpt-4o-mini';
    _geminiModel = prefs.getString('ai_gemini_model') ?? 'gemini-1.5-flash';
    _groqModel = prefs.getString('ai_groq_model') ?? 'llama-3.3-70b-versatile';

    notifyListeners();
  }

  Future<void> updateProvider(AiProviderType provider) async {
    _selectedProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', provider.name);
    notifyListeners();
  }

  Future<void> saveApiKeys({
    required String openAiKey,
    required String geminiKey,
    required String groqKey,
    required String openAiModel,
    required String geminiModel,
    required String groqModel,
    required AiProviderType provider,
  }) async {
    _openAiKey = openAiKey.trim();
    _geminiKey = geminiKey.trim();
    _groqKey = groqKey.trim();
    _openAiModel = openAiModel.trim();
    _geminiModel = geminiModel.trim();
    _groqModel = groqModel.trim();
    _selectedProvider = provider;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', provider.name);
    await prefs.setString('ai_openai_key', _openAiKey);
    await prefs.setString('ai_gemini_key', _geminiKey);
    await prefs.setString('ai_groq_key', _groqKey);
    await prefs.setString('ai_openai_model', _openAiModel);
    await prefs.setString('ai_gemini_model', _geminiModel);
    await prefs.setString('ai_groq_model', _groqModel);

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final loadingMsg = AiMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.assistant,
      text: 'جارِ التفكير وتنفيذ العمليات المطلوبة في نظام المحاسبة...',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(userMsg);
    _messages.add(loadingMsg);
    _isLoading = true;
    notifyListeners();

    final response = await AiService.sendMessage(
      prompt: text.trim(),
      history: _messages.where((m) => m.id != userMsg.id && !m.isLoading).toList(),
      provider: _selectedProvider,
      apiKey: currentApiKey,
      model: currentModel,
    );

    _messages.removeWhere((m) => m.isLoading);
    _messages.add(response);
    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }
}
