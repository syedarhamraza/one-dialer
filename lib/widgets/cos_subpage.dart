import 'package:flutter/material.dart';

import '../theme/one_ui_scroll.dart';
import 'one_ui_status_bar_scrim.dart';
import 'round_header_controls.dart';

/// A ColorOS 17 subpage, laid out like the contact page: black, the round glass Back
/// button with the title beside it pinned at the top, and the content (cards) scrolling
/// under it.
class CosSubpage extends StatelessWidget {
  const CosSubpage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const double _button = 48;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            physics: const OneUIScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, padding.top + 8 + _button + 20, 16, padding.bottom + 32),
            children: children,
          ),
          const Positioned(left: 0, right: 0, top: 0, child: OneUIStatusBarScrim()),
          Positioned(
            left: 16,
            right: 16,
            top: padding.top + 8,
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
