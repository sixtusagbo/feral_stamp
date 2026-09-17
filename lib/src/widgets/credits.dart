import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// Credit for the original, and where this rebuild lives.
class Credits extends StatelessWidget {
  const Credits({super.key});

  static final _original = Uri.parse('https://feralui.dev/stamp');
  static final _source = Uri.parse('https://github.com/sixtusagbo/feral_stamp');

  static void _open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: 'Helvetica Neue',
      fontSize: 12,
      color: Tone.muted,
    );
    final link = base.copyWith(
      color: Tone.text,
      decoration: TextDecoration.underline,
      decorationColor: Tone.cardEdge,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'A Flutter rebuild of '),
          TextSpan(
            text: 'Stamp by FeralUI',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => _open(_original),
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: 'Source on GitHub',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => _open(_source),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
