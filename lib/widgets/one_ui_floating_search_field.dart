import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

import 'one_ui_glass_surface.dart';
import '../core/haptics/haptics.dart';
import '../core/speech/voice_input.dart';

/// Floating glass search capsule that sits above the keyboard (Subscriptions, Settings).
/// Shows a clear button while [controller] has text. While it's empty, and the phone has a
/// voice typing screen, a mic sits in the same place (when [onVoiceResult] is given).
class OneUIFloatingSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after the text is cleared with the ✕ button.
  final VoidCallback? onCleared;

  /// Called with what was said after the mic filled the field. Null hides the mic.
  final ValueChanged<String>? onVoiceResult;
  final bool autofocus;

  const OneUIFloatingSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.onVoiceResult,
    this.autofocus = false,
  });

  Future<void> _listen() async {
    Haptics.tap();
    final heard = await VoiceInput.listen(hintText);
    if (heard == null) return;
    controller.value = TextEditingValue(
      text: heard,
      selection: TextSelection.collapsed(offset: heard.length),
    );
    onChanged?.call(heard);
    onVoiceResult?.call(heard);
  }

  Widget _button({required String label, required IconData icon, required VoidCallback onTap}) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 32, height: 32, child: Icon(icon, color: Colors.white70, size: 20)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return OneUIGlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              style: TextStyle(color: context.palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF8E95B8), fontSize: 16, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isNotEmpty) {
                return _button(
                  label: 'Clear search',
                  icon: Icons.close_rounded,
                  onTap: () {
                    Haptics.tap();
                    controller.clear();
                    onChanged?.call('');
                    onCleared?.call();
                  },
                );
              }
              if (onVoiceResult == null) return const SizedBox.shrink();
              return FutureBuilder<bool>(
                future: VoiceInput.available(),
                builder: (context, snapshot) => snapshot.data == true
                    ? _button(label: 'Search by voice', icon: Icons.mic_rounded, onTap: _listen)
                    : const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }
}
