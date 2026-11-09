import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../l10n/l10n.dart';

/// Edit the "Decline with SMS" texts (up to [max]).
class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key});

  static const max = 6;

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  final _telecom = TelecomBridge.instance;
  List<String>? _replies;

  @override
  void initState() {
    super.initState();
    _telecom.getQuickReplies().then((r) {
      if (mounted) setState(() => _replies = r);
    });
  }

  Future<void> _save(List<String> replies) async {
    setState(() => _replies = replies);
    await _telecom.setQuickReplies(replies);
  }

  Future<void> _edit(int? index) async {
    final replies = _replies!;
    final text = await showCosTextInput(
      context,
      title: context.l10n.quickDeclineMessage,
      initialValue: index == null ? '' : replies[index],
      maxLength: 160, // one SMS
    );
    if (text == null || text.isEmpty) return;
    final next = [...replies];
    index == null ? next.add(text) : next[index] = text;
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final replies = _replies;
    return OneUISubpage(
      title: context.l10n.quickDeclineMessages,
      builder: (context) => [
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 4), // text lines up with the rows below
          child: Text(
            context.l10n.quickDeclineHint,
            style: TextStyle(fontSize: 13.5, color: context.palette.textSecondary),
          ),
        ),
        if (replies != null)
          OneUIGroupCard(
            items: [
              for (var i = 0; i < replies.length; i++)
                OneUIGroupItem(
                  title: replies[i],
                  onTap: () => _edit(i),
                  trailing: IconButton(
                    tooltip: context.l10n.delete,
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: OneUITheme.accentRed),
                    onPressed: replies.length == 1 ? null : () => _save([...replies]..removeAt(i)),
                  ),
                ),
              if (replies.length < QuickRepliesScreen.max)
                OneUIGroupItem(
                  leading: const Icon(Icons.add_rounded, color: OneUITheme.accentBlue),
                  title: context.l10n.addMessage,
                  onTap: () => _edit(null),
                  trailing: const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}
