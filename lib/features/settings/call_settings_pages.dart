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
import '../../l10n/l10n.dart';

/// The native call settings (`CallPrefs.kt`) as notifiers, read once when a page opens.
class _CallSettings {
  _CallSettings() {
    TelecomBridge.instance.getCallSettings().then((s) {
      // The page may have closed before the settings arrived.
      if (_disposed) return;
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

  bool _disposed = false;

  void dispose() {
    _disposed = true;
    for (final n in [incomingStyle, vibrate, speaker, autoAnswer, delay, announce]) {
      n.dispose();
    }
  }

  void set<T extends Object>(ValueNotifier<T> notifier, String key, T value) {
    notifier.value = value;
    TelecomBridge.instance.setCallSetting(key, value);
  }
}

/// Settings' effect levels, for Reduce visual effects and Call screen effects.
Map<String, String> edgeGlowLabels(AppLocalizations l10n) => {
  'classic': l10n.edgeGlowClassic,
  'soft': l10n.edgeGlowSoft,
  'bold': l10n.edgeGlowBold,
};

Map<String, String> effectsLabels(AppLocalizations l10n) => {
  'full': l10n.effectsFull,
  'reduced': l10n.effectsReduced,
  'off': l10n.effectsOff,
};

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
      // As round as the 20 px preview ball, and as short against it as on the call screen.
      final hint = ArcHint(c, radius: 10, stroke: 1.2, sweep: .6);
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

  static Map<String, String> _announce(AppLocalizations l10n) => {
    'off': l10n.off,
    'always': l10n.always,
    'headset': l10n.onlyWithHeadphones,
  };

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosSubpage(
      title: context.l10n.incomingCallReminders,
      children: [
        ShowcasePicker(
          value: _settings.incomingStyle,
          onPick: (v) => _settings.set(_settings.incomingStyle, 'incomingStyle', v),
          footnote: context.l10n.incomingFootnote,
          options: [
            ShowcaseOption(
              value: 'banner',
              label: context.l10n.banner,
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
            ShowcaseOption(
              value: 'full',
              label: context.l10n.fullScreen,
              preview: const PhonePreview(child: Stack(children: [_callButtons])),
            ),
          ],
        ),
        OneUIGroupCard(
          items: [
            choiceRow(
              context,
              title: context.l10n.announceCalls,
              subtitle: context.l10n.announceCallsSubtitle,
              anchor: _announceKey,
              value: _settings.announce,
              labels: _announce(context.l10n),
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
  final _glassKey = GlobalKey();

  static Map<String, String> _directions(AppLocalizations l10n) => {
    'up': l10n.swipeUpToAnswer,
    'down': l10n.swipeDownToAnswer,
  };

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return CosSubpage(
      title: context.l10n.answerButtons,
      children: [
        ShowcasePicker(
          value: DialerPrefs.instance.answerStyle,
          onPick: DialerPrefs.instance.setAnswerStyle,
          options: [
            ShowcaseOption(
              value: 'two',
              label: context.l10n.twoButtons,
              preview: const PhonePreview(child: Stack(children: [_callButtons])),
            ),
            ShowcaseOption(
              value: 'one',
              label: context.l10n.oneButton,
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
        ListenableBuilder(
          listenable: Listenable.merge([prefs.answerStyle, prefs.callEffects]),
          builder: (context, _) => OneUIGroupCard(
            items: [
              // Only 1 button has a direction to choose.
              if (prefs.answerStyle.value == 'one')
                choiceRow(
                  context,
                  title: context.l10n.answerCall,
                  anchor: _directionKey,
                  value: prefs.answerDirection,
                  labels: _directions(context.l10n),
                  onPick: prefs.setAnswerDirection,
                ),
              choiceRow(
                context,
                title: context.l10n.callScreenEffects,
                subtitle: context.l10n.callScreenEffectsSubtitle,
                anchor: _effectsKey,
                value: prefs.callEffects,
                labels: effectsLabels(context.l10n),
                onPick: prefs.setCallEffects,
              ),
              // Styles the full-effects glass only.
              if (prefs.callEffects.value == 'full')
                choiceRow(
                  context,
                  title: context.l10n.callScreenEdgeGlow,
                  anchor: _glassKey,
                  value: prefs.callGlass,
                  labels: edgeGlowLabels(context.l10n),
                  onPick: prefs.setCallGlass,
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

  static Map<String, String> _delays(AppLocalizations l10n) => {
    for (final s in [3, 5, 10]) '$s': l10n.secondsCount(s),
  };

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return CosSubpage(
      title: context.l10n.answerEndCalls,
      children: [
        OneUIGroupCard(
          items: [switchRow(context.l10n.vibrateAnswerEnd, s.vibrate, (v) => s.set(s.vibrate, 'vibrateAnswerEnd', v))],
        ),
        // Delay only matters while auto-answer is on, so it shows only then.
        ValueListenableBuilder(
          valueListenable: s.autoAnswer,
          builder: (context, auto, _) => OneUIGroupCard(
            items: [
              switchRow(
                context.l10n.autoAnswer,
                s.autoAnswer,
                (v) => s.set(s.autoAnswer, 'autoAnswer', v),
                subtitle: context.l10n.autoAnswerSubtitle,
              ),
              if (auto)
                choiceRow(
                  context,
                  title: context.l10n.autoAnswerDelay,
                  anchor: _delayKey,
                  value: s.delay,
                  labels: _delays(context.l10n),
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
              title: context.l10n.replyWithSms,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuickRepliesScreen())),
            ),
            switchRow(
              context.l10n.speakerDefault,
              s.speaker,
              (v) => s.set(s.speaker, 'speakerDefault', v),
              subtitle: context.l10n.speakerDefaultSubtitle,
            ),
          ],
        ),
      ],
    );
  }
}
