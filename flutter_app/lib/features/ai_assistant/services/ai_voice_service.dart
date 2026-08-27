import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AiVoiceService {
  static final SpeechToText _speech = SpeechToText();
  static final FlutterTts _tts = FlutterTts();

  static bool _isSpeechInitialized = false;
  static bool _isTtsInitialized = false;
  static bool isListening = false;
  static bool isSpeaking = false;

  // Initialize Speech and TTS
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

      if (!_isTtsInitialized) {
        await _tts.setLanguage('ar-SA');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);

        _tts.setStartHandler(() {
          isSpeaking = true;
        });

        _tts.setCompletionHandler(() {
          isSpeaking = false;
        });

        _tts.setErrorHandler((msg) {
          isSpeaking = false;
          debugPrint('TTS Error: $msg');
        });

        _isTtsInitialized = true;
      }

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Voice Service Init Error: $e');
      return false;
    }
  }

  // Start listening to user voice
  static Future<void> startListening({
    required Function(String recognizedWords) onResult,
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
      isListening = true;
      onStatus?.call('listening');

      await _speech.listen(
        localeId: 'ar_SA',
        listenMode: ListenMode.confirmation,
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            onResult(words);
          }
        },
        onSoundLevelChange: onSoundLevelChange,
        cancelOnError: true,
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

  // Speak AI Response
  static Future<void> speak(String text, {Function()? onComplete}) async {
    if (!_isTtsInitialized) {
      await initialize();
    }

    try {
      // Clean markdown tags and emojis for smoother speech
      final cleanText = text
          .replaceAll(RegExp(r'\*+'), '')
          .replaceAll(RegExp(r'#+'), '')
          .replaceAll(RegExp(r'•'), '')
          .replaceAll(RegExp(r'[✅❌📊🔍⚡🌳📑🧾👥📦🗄️]'), '')
          .trim();

      if (cleanText.isEmpty) return;

      isSpeaking = true;
      if (onComplete != null) {
        _tts.setCompletionHandler(() {
          isSpeaking = false;
          onComplete();
        });
      }

      await _tts.speak(cleanText);
    } catch (e) {
      isSpeaking = false;
      debugPrint('TTS Speak Error: $e');
    }
  }

  // Stop speaking
  static Future<void> stopSpeaking() async {
    if (isSpeaking) {
      await _tts.stop();
      isSpeaking = false;
    }
  }

  // Dispose all
  static Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}
