import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'call_glass.dart';
import 'round_header_controls.dart';
import '../l10n/l10n.dart';

/// ColorOS's search row: the glass search field across the top, Cancel beside it.
class SearchBarRow extends StatelessWidget {
  const SearchBarRow({super.key, required this.controller, required this.onCancel, this.onSubmitted, this.hint});

  final TextEditingController controller;
  final VoidCallback onCancel;
  final ValueChanged<String>? onSubmitted;
  final String? hint;

  static const double _bar = 48;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SearchField(
            controller: controller,
            onSubmitted: onSubmitted,
            hint: hint ?? context.l10n.searchContacts,
          ),
        ),
        const SizedBox(width: 10),
        CallGlass(
          radius: _bar / 2,
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textPrimary,
              minimumSize: const Size(0, _bar),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
            ),
            child: Text(context.l10n.cancel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

/// ColorOS's search field: a glass stadium with the magnifier, the query and a clear button.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSubmitted, required this.hint});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return CallGlass(
      radius: 24,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 26, color: context.palette.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(fontSize: 17),
                  cursorColor: OneUITheme.accentBlue,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 17, color: context.palette.textSecondary),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox(width: 12)
                    : IconButton(
                        tooltip: context.l10n.clear,
                        onPressed: controller.clear,
                        icon: Icon(Icons.cancel_rounded, size: 22, color: context.palette.textSecondary),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-place search for subpages and pickers: a search button beside [leading] that swaps the
/// header for [SearchBarRow]; Back or Cancel closes search (and clears it) before leaving.
class ExpandableSearchHeader extends StatefulWidget {
  const ExpandableSearchHeader({super.key, required this.leading, required this.controller, this.hint});
  final Widget leading;
  final TextEditingController controller;
  final String? hint;
  @override
  State<ExpandableSearchHeader> createState() => _ExpandableSearchHeaderState();
}

class _ExpandableSearchHeaderState extends State<ExpandableSearchHeader> {
  bool _searching = false;

  void _close() {
    FocusScope.of(context).unfocus();
    widget.controller.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_searching,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _searching) _close();
    },
    child: SizedBox(
      height: 48,
      // A cross-fade only, as the Contacts header did: moving the glass would need a
      // transform over its blur, which costs tens of ms a frame on Adreno.
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
        child: _searching
            ? SearchBarRow(
                key: const ValueKey(true),
                controller: widget.controller,
                hint: widget.hint,
                onCancel: _close,
              )
            : Row(
                key: const ValueKey(false),
                children: [
                  Expanded(child: widget.leading),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: Icons.search_rounded,
                    tooltip: context.l10n.search,
                    onTap: () => setState(() => _searching = true),
                  ),
                ],
              ),
      ),
    ),
  );
}
