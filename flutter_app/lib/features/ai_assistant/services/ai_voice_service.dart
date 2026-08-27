import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AiVoiceService {
  static final SpeechToText _speech = SpeechToText();

  static bool _isSpeechInitialized = false;
  static bool isListening = false;
  static bool isSpeaking = false;

  // Initialize Speech
  static Future<bool> initialize() async {
    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onError: (val) => debugPrint('STT Error: $val'),
          onStatus: (val) {
            debugPrint('STT Status: $val');
            isListening = val == 'listening';
          },
        );
      }

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Voice Service Init Error: $e');
      return false;
    }
  }

  static String? _cachedLocaleId;

  // Resolve best Arabic locale available on this device
  static Future<String?> getArabicLocale() async {
    if (_cachedLocaleId != null) return _cachedLocaleId;
    try {
      final locales = await _speech.locales();
      for (final loc in locales) {
        if (loc.localeId.toLowerCase().startsWith('ar')) {
          _cachedLocaleId = loc.localeId;
          debugPrint('Found STT Arabic Locale: $_cachedLocaleId (${loc.name})');
          return _cachedLocaleId;
        }
      }
      _cachedLocaleId = 'ar_SA';
      return _cachedLocaleId;
    } catch (e) {
      _cachedLocaleId = 'ar_SA';
      return _cachedLocaleId;
    }
  }

  // Start listening to user voice
  static Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    Function(String status)? onStatus,
  }) async {
    if (!_isSpeechInitialized) {
      final ok = await initialize();
      if (!ok) {
        onStatus?.call('speech_not_available');
        return;
      }
    }

    if (isSpeaking) {
      await stopSpeaking();
    }

    try {
      final locale = await getArabicLocale();
      isListening = true;
      onStatus?.call('listening');

      await _speech.listen(
        localeId: locale,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(seconds: 4),
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            onResult(words, result.finalResult);
          }
        },
        onSoundLevelChange: onSoundLevelChange,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      isListening = false;
      debugPrint('STT Listen Error: $e');
      onStatus?.call('error');
    }
  }

  // Stop listening
  static Future<void> stopListening() async {
    if (isListening || _speech.isListening) {
      await _speech.stop();
      isListening = false;
    }
  }

  // Speak AI Response (Muted / Silent by default to avoid OS language voice mismatches)
  static bool enableVoiceAudio = false;

  static Future<void> speak(String text, {Function()? onComplete}) async {
    // Silent mode for immediate visual execution
    onComplete?.call();
  }

  // Stop speaking
  static Future<void> stopSpeaking() async {
    isSpeaking = false;
  }

  // Dispose all
  static Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}
