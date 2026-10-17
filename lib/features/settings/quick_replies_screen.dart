import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../theme/one_ui_theme.dart';
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
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ReplyDialog(initial: index == null ? '' : replies[index]),
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

/// Owns its text controller so it outlives the close animation.
class _ReplyDialog extends StatefulWidget {
  const _ReplyDialog({required this.initial});

  final String initial;

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick decline message'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 160, // one SMS
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: const Text('Save')),
      ],
    );
  }
}
