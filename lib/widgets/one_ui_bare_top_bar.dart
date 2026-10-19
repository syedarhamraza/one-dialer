import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// Top bar for full-page heroes with no title (Software update, About): a back
/// chevron on the left and an optional action on the right.
class OneUIBareTopBar extends StatelessWidget {
  final Widget? trailing;

  const OneUIBareTopBar({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: OneUITheme.textPrimary),
              ),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
