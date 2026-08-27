import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_assistant_provider.dart';
import '../services/ai_voice_service.dart';
import '../models/ai_message.dart';

class AiVoiceCallScreen extends StatefulWidget {
  const AiVoiceCallScreen({super.key});

  @override
  State<AiVoiceCallScreen> createState() => _AiVoiceCallScreenState();
}

class _AiVoiceCallScreenState extends State<AiVoiceCallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  Timer? _callDurationTimer;
  int _callDurationSeconds = 0;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _liveSpeechText = '';
  String _assistantSpeechText = '';
  String _callStatus = 'connecting'; // connecting, listening, processing, speaking
  List<AiToolAction> _lastActions = [];

  Timer? _speechSilenceTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startCall();
  }

  void _startCall() async {
    _startTimer();
    setState(() {
      _callStatus = 'speaking';
      _assistantSpeechText = 'مرحباً بك! أنا مساعدك المحاسبي الذكي. كيف أقدر أساعدك اليوم في حساباتك ومستودعاتك؟';
    });

    await AiVoiceService.initialize();
    if (!mounted) return;

    await AiVoiceService.speak(_assistantSpeechText, onComplete: () {
      if (mounted && !_isMuted) {
        _listenToUser();
      }
    });
  }

  void _startTimer() {
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _listenToUser() async {
    if (_isMuted || !mounted) return;

    setState(() {
      _callStatus = 'listening';
      _liveSpeechText = '';
    });

    await AiVoiceService.startListening(
      onResult: (words) {
        if (!mounted) return;
        setState(() {
          _liveSpeechText = words;
        });

        // Reset silence timer whenever new words arrive
        _speechSilenceTimer?.cancel();
        _speechSilenceTimer = Timer(const Duration(milliseconds: 1500), () {
          // If user stopped speaking for 1.5 seconds, process the command!
          if (_liveSpeechText.trim().isNotEmpty) {
            _processUserVoiceCommand(_liveSpeechText.trim());
          }
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          if (_callStatus == 'listening' && _liveSpeechText.trim().isNotEmpty) {
            _processUserVoiceCommand(_liveSpeechText.trim());
          }
        }
      },
    );
  }

  void _processUserVoiceCommand(String prompt) async {
    _speechSilenceTimer?.cancel();
    await AiVoiceService.stopListening();

    if (!mounted) return;

    setState(() {
      _callStatus = 'processing';
      _assistantSpeechText = 'جاري التحقق وتنفيذ العملية في قاعدة البيانات...';
      _lastActions = [];
    });

    final provider = context.read<AiAssistantProvider>();

    try {
      await provider.sendMessage(
        prompt,
        onRealtimeSpokenResponse: (responseText, actions) async {
          if (!mounted) return;

          setState(() {
            _callStatus = 'speaking';
            _assistantSpeechText = responseText;
            _lastActions = actions ?? [];
          });

          await AiVoiceService.speak(responseText, onComplete: () {
            if (mounted && !_isMuted) {
              // Automatically listen for the next sentence!
              _listenToUser();
            } else if (mounted) {
              setState(() {
                _callStatus = 'idle';
              });
            }
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _callStatus = 'error';
        _assistantSpeechText = 'حدث خطأ أثناء معالجة الأمر: $e';
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isMuted) {
      AiVoiceService.stopListening();
      setState(() {
        _callStatus = 'idle';
      });
    } else {
      _listenToUser();
    }
  }

  void _endCall() async {
    _callDurationTimer?.cancel();
    _speechSilenceTimer?.cancel();
    await AiVoiceService.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _speechSilenceTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    AiVoiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep futuristic slate dark
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Title, Status, and Call Duration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                    onPressed: _endCall,
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _callStatus == 'error' ? Colors.red : Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'اتصال صوتي مباشر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(_callDurationSeconds),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Status Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor().withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Glowing Pulsating Wave Orb (Siri / Gemini Live Style)
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  final glowRadius = 40.0 + (_pulseController.value * 30.0);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Ambient Ring
                      Container(
                        width: 220 * scale,
                        height: 220 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor().withValues(alpha: 0.05),
                        ),
                      ),
                      // Middle Pulse Ring
                      Container(
                        width: 170 * scale,
                        height: 170 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor().withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor().withValues(alpha: 0.3),
                              blurRadius: glowRadius,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      // Core Orb
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getStatusColor(),
                              _getStatusColor().withValues(alpha: 0.7),
                              primaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor().withValues(alpha: 0.6),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _callStatus == 'speaking'
                                ? Icons.graphic_eq_rounded
                                : (_callStatus == 'listening' ? Icons.mic_rounded : Icons.auto_awesome_rounded),
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(),

            // Real-time Action Badges (if any ERP tool executed)
            if (_lastActions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _lastActions.map((action) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'أداة: ${action.toolName} - تم التنفيذ والترحيل',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Live Spoken Content Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_liveSpeechText.isNotEmpty) ...[
                      Row(
                        children: const [
                          Icon(Icons.person_rounded, size: 14, color: Colors.white70),
                          SizedBox(width: 6),
                          Text('أنت:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _liveSpeechText,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Divider(color: Colors.white12, height: 16),
                    ],
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                        SizedBox(width: 6),
                        Text('المساعد المحاسبي:', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _assistantSpeechText.isEmpty ? 'في انتظار استفسارك أو أمرك المحاسبي...' : _assistantSpeechText,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Call Control Actions
            Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildControlCircle(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'إلغاء الكتم' : 'كتم الصوت',
                    isActive: _isMuted,
                    onTap: _toggleMute,
                  ),

                  // End Call Button (Big Red)
                  InkWell(
                    onTap: _endCall,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),

                  // Push to Listen / Interrupt Button
                  _buildControlCircle(
                    icon: Icons.refresh_rounded,
                    label: 'إعادة الاستماع',
                    isActive: _callStatus == 'listening',
                    onTap: () {
                      if (_callStatus == 'speaking') {
                        AiVoiceService.stopSpeaking();
                      }
                      _listenToUser();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black87 : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_callStatus) {
      case 'listening':
        return Colors.greenAccent;
      case 'processing':
        return Colors.amberAccent;
      case 'speaking':
        return Colors.cyanAccent;
      case 'error':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getStatusIcon() {
    switch (_callStatus) {
      case 'listening':
        return Icons.mic_rounded;
      case 'processing':
        return Icons.hourglass_top_rounded;
      case 'speaking':
        return Icons.volume_up_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      default:
        return Icons.phone_in_talk_rounded;
    }
  }

  String _getStatusLabel() {
    switch (_callStatus) {
      case 'listening':
        return 'المساعد يستمع إليك الآن...';
      case 'processing':
        return 'جاري معالجة الأمر في قاعدة البيانات...';
      case 'speaking':
        return 'المساعد يتحدث ويشرح النتائج...';
      case 'error':
        return 'حدث خطأ في الاتصال';
      default:
        return 'المكالمة متصلة وجاهزة';
    }
  }
}
