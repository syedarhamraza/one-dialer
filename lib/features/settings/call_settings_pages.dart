import 'package:flutter/material.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/showcase_picker.dart';
import '../in_call/call_controls.dart' show answerGreen, endRed;
import '../in_call/incoming_controls.dart' show ArcHint, oneButtonWhite;
import 'quick_replies_screen.dart';

/// The native call settings (`CallPrefs.kt`) as notifiers, read once when a page opens.
class _CallSettings {
  _CallSettings() {
    TelecomBridge.instance.getCallSettings().then((s) {
      if (s['incomingStyle'] case final String v) incomingStyle.value = v;
      if (s['vibrateAnswerEnd'] case final bool v) vibrate.value = v;
      if (s['speakerDefault'] case final bool v) speaker.value = v;
      if (s['autoAnswer'] case final bool v) autoAnswer.value = v;
      if (s['autoAnswerDelay'] case final int v) delay.value = '$v';
      if (s['announceCalls'] case final String v) announce.value = v;
    });
  }

  final incomingStyle = ValueNotifier('banner');
  final vibrate = ValueNotifier(true);
  final speaker = ValueNotifier(false);
  final autoAnswer = ValueNotifier(false);
  final delay = ValueNotifier<String?>('5');
  final announce = ValueNotifier('off');

  void set<T extends Object>(ValueNotifier<T> notifier, String key, T value) {
    notifier.value = value;
    TelecomBridge.instance.setCallSetting(key, value);
  }
}

/// Settings' effect levels, for Reduce visual effects and Call screen effects.
const effectsLabels = {'full': 'Full effects', 'reduced': 'Reduced effects', 'off': 'Effects off'};

/// Decline and Answer at the bottom of a [PhonePreview], each under its swipe arc.
const _callButtons = Positioned(
  left: 0,
  right: 0,
  bottom: 30,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _Hinted(
        PreviewCallButton(color: endRed, icon: Icons.call_end_rounded),
        up: endRed,
      ),
      _Hinted(
        PreviewCallButton(color: answerGreen, icon: Icons.call_rounded),
        up: answerGreen,
      ),
    ],
  ),
);

/// A preview button with the call screen's swipe arcs, small: [up] above it, [down] below.
class _Hinted extends StatelessWidget {
  const _Hinted(this.button, {required this.up, this.down});

  final Widget button;
  final Color up;
  final Color? down;

  @override
  Widget build(BuildContext context) {
    Widget arc(Color c) {
      final hint = ArcHint(c, radius: 7, stroke: 1.6);
      return CustomPaint(size: hint.size, painter: hint);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        arc(up),
        const SizedBox(height: 3),
        button,
        if (down case final d?) ...[const SizedBox(height: 3), RotatedBox(quarterTurns: 2, child: arc(d))],
      ],
    );
  }
}

/// Settings › Incoming call reminders: how a call rings while the phone is unlocked.
class IncomingCallRemindersScreen extends StatefulWidget {
  const IncomingCallRemindersScreen({super.key});

  @override
  State<IncomingCallRemindersScreen> createState() => _IncomingCallRemindersScreenState();
}

class _IncomingCallRemindersScreenState extends State<IncomingCallRemindersScreen> {
  final _settings = _CallSettings();
  final _announceKey = GlobalKey();

  static const _announce = {'off': 'Off', 'always': 'Always', 'headset': 'Only with headphones'};

  @override
  Widget build(BuildContext context) {
    return CosSubpage(
      title: 'Incoming call reminders',
      children: [
        ShowcasePicker(
          value: _settings.incomingStyle,
          onPick: (v) => _settings.set(_settings.incomingStyle, 'incomingStyle', v),
          footnote: 'Applies only to incoming calls received when your device is unlocked.',
          options: [
            ShowcaseOption(
              value: 'banner',
              label: 'Banner',
              preview: PhonePreview(
                showCaller: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFF1E2C3E), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 40, height: 4, child: ColoredBox(color: Colors.white54)),
                              SizedBox(height: 4),
                              SizedBox(width: 28, height: 3, child: ColoredBox(color: Colors.white30)),
                            ],
                          ),
                        ),
                        PreviewCallButton(color: endRed, icon: Icons.call_end_rounded, size: 13),
                        SizedBox(width: 4),
                        PreviewCallButton(color: answerGreen, icon: Icons.call_rounded, size: 13),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const ShowcaseOption(
              value: 'full',
              label: 'Full screen',
              preview: PhonePreview(child: Stack(children: [_callButtons])),
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: 'Announce incoming calls',
              subtitle: "Says the caller's name while it rings",
              anchor: _announceKey,
              value: _settings.announce,
              labels: _announce,
              onPick: (v) => _settings.set(_settings.announce, 'announceCalls', v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Settings › Answer buttons: whether the call screen answers with two buttons or one.
class AnswerButtonsScreen extends StatefulWidget {
  const AnswerButtonsScreen({super.key});

  @override
  State<AnswerButtonsScreen> createState() => _AnswerButtonsScreenState();
}

class _AnswerButtonsScreenState extends State<AnswerButtonsScreen> {
  final _directionKey = GlobalKey();
  final _effectsKey = GlobalKey();

  static const _directions = {'up': 'Swipe up to answer', 'down': 'Swipe down to answer'};

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return CosSubpage(
      title: 'Answer buttons',
      children: [
        ShowcasePicker(
          value: DialerPrefs.instance.answerStyle,
          onPick: DialerPrefs.instance.setAnswerStyle,
          options: [
            const ShowcaseOption(
              value: 'two',
              label: '2 buttons',
              preview: PhonePreview(child: Stack(children: [_callButtons])),
            ),
            ShowcaseOption(
              value: 'one',
              label: '1 button',
              // Follows Answer call: the green arc is on the answering side.
              preview: PhonePreview(
                child: ValueListenableBuilder(
                  valueListenable: prefs.answerDirection,
                  builder: (context, direction, _) => Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 22,
                        child: _Hinted(
                          const PreviewCallButton(color: oneButtonWhite, icon: Icons.call_rounded, size: 22),
                          up: direction == 'down' ? endRed : answerGreen,
                          down: direction == 'down' ? answerGreen : endRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: prefs.answerStyle,
          builder: (context, style, _) => OneUIGroupCard(
            items: [
              // Only 1 button has a direction to choose.
              if (style == 'one')
                choiceRow(
                  context,
                  title: 'Answer call',
                  anchor: _directionKey,
                  value: prefs.answerDirection,
                  labels: _directions,
                  onPick: prefs.setAnswerDirection,
                ),
              choiceRow(
                context,
                title: 'Call screen effects',
                subtitle: 'Glass and glow on the call screen',
                anchor: _effectsKey,
                value: prefs.callEffects,
                labels: effectsLabels,
                onPick: prefs.setCallEffects,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings › Answer/End calls, ColorOS's page.
class AnswerEndCallsScreen extends StatefulWidget {
  const AnswerEndCallsScreen({super.key});

  @override
  State<AnswerEndCallsScreen> createState() => _AnswerEndCallsScreenState();
}

class _AnswerEndCallsScreenState extends State<AnswerEndCallsScreen> {
  final _settings = _CallSettings();
  final _delayKey = GlobalKey();

  static const _delays = {'3': '3 seconds', '5': '5 seconds', '10': '10 seconds'};

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return CosSubpage(
      title: 'Answer/End calls',
      children: [
        OneUIGroupCard(
          items: [
            switchRow(
              'Vibrate when your calls are answered/ended',
              s.vibrate,
              (v) => s.set(s.vibrate, 'vibrateAnswerEnd', v),
            ),
          ],
        ),
        // Delay only matters while auto-answer is on, so it shows only then.
        ValueListenableBuilder(
          valueListenable: s.autoAnswer,
          builder: (context, auto, _) => OneUIGroupCard(
            items: [
              switchRow(
                'Auto-answer calls when connected to external audio device',
                s.autoAnswer,
                (v) => s.set(s.autoAnswer, 'autoAnswer', v),
                subtitle: 'Includes Bluetooth and wired headphones',
              ),
              if (auto)
                choiceRow(
                  context,
                  title: 'Delay auto answer',
                  anchor: _delayKey,
                  value: s.delay,
                  labels: _delays,
                  onPick: (v) {
                    s.delay.value = v;
                    TelecomBridge.instance.setCallSetting('autoAnswerDelay', int.parse(v));
                  },
                ),
            ],
          ),
        ),
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Reply with SMS',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuickRepliesScreen())),
            ),
            switchRow(
              'Calls default to speaker',
              s.speaker,
              (v) => s.set(s.speaker, 'speakerDefault', v),
              subtitle: "Doesn't take effect when external devices are connected.",
            ),
          ],
        ),
      ],
    );
  }
}
