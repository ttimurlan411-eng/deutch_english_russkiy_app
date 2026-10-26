import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';

/// A button that pronounces [text] and reports failures honestly.
class SpeakerButton extends StatefulWidget {
  const SpeakerButton({
    super.key,
    required this.text,
    required this.speechService,
    this.languageCode = 'en',
    this.size = 20,
    this.enabled = true,
  });

  final String text;
  final SpeechService speechService;
  final String languageCode;
  final double size;

  /// When `false` the button is shown greyed out and does nothing.
  final bool enabled;

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton> {
  bool _speaking = false;

  Future<void> _handleTap() async {
    setState(() => _speaking = true);
    final result = await widget.speechService.speak(
      widget.text,
      widget.languageCode,
    );
    if (!mounted) return;
    setState(() => _speaking = false);

    if (!result) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).audioUnavailable),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.speechService.enabled;
    return IconButton(
      onPressed: !enabled || _speaking ? null : _handleTap,
      tooltip: AppLocalizations.of(context).playAudio,
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppTheme.tint : const Color(0xFFF2F3F7),
        foregroundColor: enabled ? AppTheme.primary : AppTheme.textSecondary,
        disabledForegroundColor: AppTheme.textSecondary,
      ),
      icon: _speaking
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.volume_up_rounded, size: widget.size),
    );
  }
}
