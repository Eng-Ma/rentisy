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
  String _groqModel = 'llama-3.1-8b-instant';

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
          text: 'مرحباً بك يا باشمهندس عبود! 👋 أنا **« رينتيسي (Rentisy AI) »** مساعدك ومستشارك المحاسبي الذكي 🤖💼.\n\nيمكنك مناداتي في أي وقت بـ **"يا رينتيسي"** وطلب أي عملية مالية أو استعلام (سندات، فواتير، تقارير أرباح، أصناف المستودع، عملاء، أو اتصال صوتي مباشر).\n\nكيف أقدر أساعدك اليوم؟ ✨',
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
    _groqModel = prefs.getString('ai_groq_model') ?? 'llama-3.1-8b-instant';

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

  Future<void> sendMessage(
    String text, {
    Function(String fullResponse, List<AiToolAction>? actions)? onRealtimeSpokenResponse,
  }) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    final assistantMsgId = 'asst_${DateTime.now().millisecondsSinceEpoch}';
    final initialAssistantMsg = AiMessage(
      id: assistantMsgId,
      sender: MessageSender.assistant,
      text: '',
      timestamp: DateTime.now(),
      isLoading: false,
      isStreaming: true,
    );

    _messages.add(userMsg);
    _messages.add(initialAssistantMsg);
    _isLoading = true;
    notifyListeners();

    String accumulatedText = '';
    List<AiToolAction> accumulatedActions = [];

    await AiService.sendMessageStream(
      prompt: text.trim(),
      history: _messages.where((m) => m.id != userMsg.id && m.id != assistantMsgId && !m.isLoading).toList(),
      provider: _selectedProvider,
      apiKey: currentApiKey,
      model: currentModel,
      onChunk: (chunk, {actions, isDone = false}) {
        accumulatedText += chunk;
        if (actions != null && actions.isNotEmpty) {
          accumulatedActions.addAll(actions);
        }

        final index = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: accumulatedText,
            executedActions: accumulatedActions.isNotEmpty ? accumulatedActions : null,
            isStreaming: !isDone,
          );
          notifyListeners();
        }

        if (isDone) {
          onRealtimeSpokenResponse?.call(accumulatedText, accumulatedActions);
        }
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }
}
