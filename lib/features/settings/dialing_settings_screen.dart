import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/showcase_picker.dart';

/// Settings › Keypad & recents: what a tap on a recent call does, and how dual SIM phones
/// pick a SIM. The SIM choices show only with two SIMs.
class DialingSettingsScreen extends StatefulWidget {
  const DialingSettingsScreen({super.key});

  @override
  State<DialingSettingsScreen> createState() => _DialingSettingsScreenState();
}

class _DialingSettingsScreenState extends State<DialingSettingsScreen> {
  bool _dualSim = false;

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((s) {
      if (mounted) setState(() => _dualSim = s.length > 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    return CosSubpage(
      title: l10n.keypadAndRecents,
      children: [
        ShowcaseTitle(l10n.tapRecentCall),
        ShowcasePicker(
          value: prefs.recentTap,
          onPick: prefs.setRecentTap,
          options: [
            ShowcaseOption(value: 'details', label: l10n.openDetails, preview: const _Phone(_Details())),
            ShowcaseOption(value: 'dial', label: l10n.writeInKeypad, preview: const _Phone(_Keypad(_CallRow(1)))),
            if (_dualSim)
              ShowcaseOption(value: 'sim', label: l10n.chooseSimAndCall, preview: const _Phone(_Recents(menu: true))),
          ],
        ),
        if (_dualSim) ...[
          ShowcaseTitle(l10n.chooseSimForCalls),
          ShowcasePicker(
            value: prefs.simChoice,
            onPick: prefs.setSimChoice,
            footnote: l10n.chooseSimSubtitle,
            options: [
              ShowcaseOption(value: 'buttons', label: l10n.twoCallButtons, preview: const _Phone(_Keypad(_CallRow(2)))),
              ShowcaseOption(
                value: 'menu',
                label: l10n.askEveryTime,
                preview: const _Phone(
                  Stack(
                    children: [
                      Positioned.fill(child: _Keypad(_CallRow(1))),
                      Positioned(right: 10, bottom: 42, child: _SimMenu()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A [PhonePreview] of the app's own black pages.
class _Phone extends StatelessWidget {
  const _Phone(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => PhonePreview(
    showCaller: false,
    screen: const BoxDecoration(color: Colors.black),
    child: child,
  );
}

const _green = OneUITheme.dialGreen;
const _avatarColors = [Color(0xFF5390F5), Color(0xFF48B5A0), Color(0xFFF4A261), Color(0xFF7E57C2), Color(0xFFF07167)];

/// A contact's page: avatar, name, number and its round actions.
class _Details extends StatelessWidget {
  const _Details();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 34),
    child: Column(
      children: [
        CircleAvatar(radius: 17, backgroundColor: Color(0xFF5390F5)),
        SizedBox(height: 10),
        PreviewBar(46, 6, .8),
        SizedBox(height: 6),
        PreviewBar(34, 3, .4),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PreviewCallButton(color: _green, icon: Icons.call_rounded, size: 18),
            SizedBox(width: 8),
            PreviewCallButton(color: Color(0xFF2C2C2E), icon: Icons.message_rounded, size: 18),
            SizedBox(width: 8),
            PreviewCallButton(color: Color(0xFF2C2C2E), icon: Icons.videocam_rounded, size: 18),
          ],
        ),
      ],
    ),
  );
}

/// The Calls list, with the tapped row's SIM menu over it when [menu].
class _Recents extends StatelessWidget {
  const _Recents({this.menu = false});

  final bool menu;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 30, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PreviewBar(36, 8, .8),
            const SizedBox(height: 12),
            for (final (i, color) in _avatarColors.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: color),
                    const SizedBox(width: 6),
                    PreviewBar(i.isEven ? 34 : 26, 3, .55),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (menu) const Positioned(left: 26, top: 76, child: _SimMenu()),
    ],
  );
}

/// The keypad: the typed number, the 12 keys and [bottom], its call row.
class _Keypad extends StatelessWidget {
  const _Keypad(this.bottom);

  final Widget bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 44, 14, 18),
    child: Column(
      children: [
        const PreviewBar(54, 7, .85),
        const Spacer(),
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var key = 0; key < 3; key++)
                  Container(
                    width: 22,
                    height: 13,
                    decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(7)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        bottom,
      ],
    ),
  );
}

/// The keypad's green Call button, or one per SIM.
class _CallRow extends StatelessWidget {
  const _CallRow(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Container(
          width: count == 1 ? 40 : 30,
          height: 16,
          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.call_rounded, size: 10, color: Colors.white),
        ),
      ],
    ],
  );
}

/// The SIM chooser menu: two SIMs, each a coloured chip and a name.
class _SimMenu extends StatelessWidget {
  const _SimMenu();

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF3A3A3C),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
    ),
    child: Column(
      children: [
        for (final color in const [Color(0xFF5390F5), Color(0xFFF4A261)])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 7, height: 9, child: ColoredBox(color: color)),
                const SizedBox(width: 5),
                const PreviewBar(26, 3, .7),
              ],
            ),
          ),
      ],
    ),
  );
}
