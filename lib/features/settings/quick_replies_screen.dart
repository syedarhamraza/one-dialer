import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_group_card.dart';

/// Edit the "Decline with message" texts (up to [max]).
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
    final typed = await OneUIFloatingModal.showTextInputDialog(
      context: context,
      title: 'Quick decline message',
      initialValue: index == null ? '' : replies[index],
    );
    if (typed == null || typed.isEmpty) return;
    // One SMS. shortcut: the shared input modal (verbatim OneSpend) has no counter, so longer
    // text is cut here; give the modal a maxLength if people hit it.
    final text = typed.length > 160 ? typed.substring(0, 160) : typed;
    final next = [...replies];
    index == null ? next.add(text) : next[index] = text;
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final replies = _replies;
    return OneUISubpage(
      title: 'Quick decline messages',
      builder: (context) => [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Sent when you decline a call with a message',
            style: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
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
                    tooltip: 'Delete',
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: OneUITheme.accentRed),
                    onPressed: replies.length == 1 ? null : () => _save([...replies]..removeAt(i)),
                  ),
                ),
              if (replies.length < QuickRepliesScreen.max)
                OneUIGroupItem(
                  leading: const Icon(Icons.add_rounded, color: OneUITheme.accentBlue),
                  title: 'Add message',
                  onTap: () => _edit(null),
                  trailing: const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}
