import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../data/quick_log_repository.dart';

class QuickLogArgs {
  const QuickLogArgs({
    required this.patientId,
    required this.patientName,
    required this.logType, // 'incident' | 'positiveMoment'
  });
  final String patientId;
  final String patientName;
  final String logType;
}

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key, required this.args});
  final QuickLogArgs args;

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _repo = QuickLogRepository();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _micAvailable = false;
  bool _isListening = false;
  bool _parsing = false;
  late final AnimationController _pulseCtrl;

  bool get _isIncident => widget.args.logType == 'incident';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initMic();
  }

  Future<void> _initMic() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _micAvailable = available);
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_micAvailable) {
      AppSnackbar.showError(context, 'Microphone not available on this device.');
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _textCtrl.text = result.recognizedWords;
          _textCtrl.selection = TextSelection.collapsed(
              offset: _textCtrl.text.length);
        });
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  Future<void> _parse() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      AppSnackbar.showError(context, 'Please describe what happened first.');
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
    setState(() => _parsing = true);
    try {
      final fields = await _repo.parseText(
        text: text,
        logType: widget.args.logType,
      );
      if (!mounted) return;
      final reviewRoute = _isIncident
          ? Routes.quickLogIncidentReview
          : Routes.quickLogPositiveMomentReview;
      context.push(reviewRoute, extra: {
        'patientId': widget.args.patientId,
        'patientName': widget.args.patientName,
        'fields': fields,
        'rawText': text,
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
            context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isIncident ? AppColors.secondaryOrange : AppColors.secondary;
    final label = _isIncident ? 'Behavioral Incident' : 'Positive Moment';
    final hint = _isIncident
        ? 'e.g. "At 3pm after a routine change, he started hitting his head against the wall for about 10 minutes. I redirected him with deep pressure and it helped."'
        : 'e.g. "She made eye contact and said hello to a stranger at the park this morning. I praised her immediately and she smiled."';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: const BackButton(color: AppColors.textMain),
        title: Text('Quick Log',
            style: AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: AppTextStyles.caption.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Text(
                'Describe what happened',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Speak or type naturally — our AI will extract the details for you.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              ),
              const SizedBox(height: 20),
              // Text area
              TextField(
                controller: _textCtrl,
                maxLines: 8,
                minLines: 6,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.caption
                      .copyWith(color: AppColors.textSubtle, height: 1.5),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: color, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              // Mic button
              Center(
                child: GestureDetector(
                  onTap: _parsing ? null : _toggleMic,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) {
                      final scale = _isListening
                          ? 1.0 + _pulseCtrl.value * 0.12
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppColors.error
                            : color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: _isListening ? AppColors.error : color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic,
                        size: 32,
                        color: _isListening ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isListening ? 'Listening… tap to stop' : 'Tap to speak',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSubtle),
                ),
              ),
              const SizedBox(height: 32),
              // Analyse button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _parsing ? null : _parse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    disabledBackgroundColor: color.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _parsing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Analyse & Review',
                          style: AppTextStyles.subtitle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
