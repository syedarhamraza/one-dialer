import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/prefs/dialer_prefs.dart';
import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_scroll.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/choice_row.dart';
import '../../widgets/cos_artwork.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/one_ui_group_card.dart';
import '../in_call/call_controls.dart';
import '../settings/call_settings_pages.dart';
import '../../core/telecom/call_info.dart';
import '../settings/dialing_settings_screen.dart';
import '../settings/display_settings_screen.dart';
import '../settings/settings_screen.dart';

/// Shown once after [SetupScreen] grants the role: the few choices a new user should make first
/// (language and theme, how calls are answered) and what incoming calls still need from Android.
/// Everything here is also in Settings, so it can be skipped.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = 4;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (MediaQuery.disableAnimationsOf(context)) return _controller.jumpToPage(page);
    _controller.animateToPage(page, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _next() => _page == _pages - 1 ? widget.onDone() : _go(_page + 1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _go(_page - 1);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: MediaQuery.sizeOf(context).height * .3,
              child: const CosArtwork(fadeToBlack: .6),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onDone,
                      child: Text(l10n.onboardingSkip, style: TextStyle(color: palette.textSecondary)),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        _Page(title: l10n.onboardingLookTitle, body: l10n.onboardingLookBody, child: const _LookCard()),
                        _Page(
                          title: l10n.onboardingAnswerTitle,
                          body: l10n.onboardingAnswerBody,
                          child: const _AnswerCard(),
                        ),
                        _Page(
                          title: l10n.onboardingCallingTitle,
                          body: l10n.onboardingCallingBody,
                          child: const _CallingCard(),
                        ),
                        _Page(
                          title: l10n.onboardingHealthTitle,
                          body: l10n.onboardingHealthBody,
                          child: const _HealthCard(),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 18 : 6,
                          height: 6,
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: i == _page ? answerGreen : palette.textSecondary.withValues(alpha: .4),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
                    child: GlowButton(
                      label: _page == _pages - 1 ? l10n.onboardingStart : l10n.onboardingNext,
                      width: double.infinity,
                      height: 56,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A title and line of text over one page's settings.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.body, required this.child});

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const HoldStillScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: context.palette.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        child,
      ],
    ),
  );
}

class _LookCard extends StatefulWidget {
  const _LookCard();

  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard> {
  final _languageKey = GlobalKey();
  final _themeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return OneUIGroupCard(
      items: [
        choiceRow(
          context,
          title: context.l10n.settingsAppLanguage,
          anchor: _languageKey,
          value: prefs.language,
          labels: languageLabels(context.l10n),
          onPick: prefs.setLanguage,
        ),
        choiceRow(
          context,
          title: context.l10n.appearance,
          anchor: _themeKey,
          value: prefs.themeMode,
          labels: DisplaySettingsScreen.themeLabels(context.l10n),
          onPick: prefs.setThemeMode,
        ),
      ],
    );
  }
}

class _AnswerCard extends StatefulWidget {
  const _AnswerCard();

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  final _directionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    return Column(
      children: [
        const AnswerStylePicker(),
        // Only 1 button has a direction to choose.
        ValueListenableBuilder(
          valueListenable: prefs.answerStyle,
          builder: (context, style, _) => style != 'one'
              ? const SizedBox.shrink()
              : OneUIGroupCard(
                  items: [
                    choiceRow(
                      context,
                      title: context.l10n.answerCall,
                      anchor: _directionKey,
                      value: prefs.answerDirection,
                      labels: answerDirectionLabels(context.l10n),
                      onPick: prefs.setAnswerDirection,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Settings › Making calls' main choices: the SIM calls use (dual SIM only), what a tap on a
/// recent call does, and swipe to call.
class _CallingCard extends StatefulWidget {
  const _CallingCard();

  @override
  State<_CallingCard> createState() => _CallingCardState();
}

class _CallingCardState extends State<_CallingCard> {
  final _simKey = GlobalKey();
  final _tapKey = GlobalKey();
  List<SimCard> _sims = const [];

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getSims().then((sims) {
      if (mounted) setState(() => _sims = sims);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = DialerPrefs.instance;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: prefs.swipeToCall,
      builder: (context, _) => OneUIGroupCard(
        items: [
          if (_sims.length > 1)
            choiceRow(
              context,
              title: l10n.chooseSimForCalls,
              anchor: _simKey,
              value: prefs.simChoice,
              labels: SimSettingsScreen.choiceLabels(l10n, _sims),
              onPick: prefs.setSimChoice,
            ),
          choiceRow(
            context,
            title: l10n.tapRecentCall,
            subtitle: l10n.tapRecentCallSubtitle,
            anchor: _tapKey,
            value: prefs.recentTap,
            labels: {'details': l10n.openDetails, 'dial': l10n.writeInKeypad, 'call': l10n.call},
            onPick: prefs.setRecentTap,
          ),
          switchRow(l10n.swipeToCall, prefs.swipeToCall, prefs.setSwipeToCall, subtitle: l10n.swipeToCallSubtitle),
        ],
      ),
    );
  }
}

/// Settings' Needs attention rows for what incoming calls need from Android, or one "All set" row.
class _HealthCard extends StatefulWidget {
  const _HealthCard();

  @override
  State<_HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends State<_HealthCard> with WidgetsBindingObserver {
  final _telecom = TelecomBridge.instance;
  Map<Object?, Object?>? _health;
  bool _bluetoothNames = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(); // back from a system settings screen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    final (health, bluetoothNames) = await (_telecom.getCallHealth(), Permission.bluetoothConnect.isGranted).wait;
    if (!mounted) return;
    setState(() {
      _health = health;
      _bluetoothNames = bluetoothNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = _health;
    if (health == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final problems = [
      if (health['notificationsEnabled'] != true)
        healthProblem(
          context,
          l10n.notificationsOff,
          l10n.notificationsOffSubtitle,
          () => _telecom.openSystemSettings('notifications'),
        ),
      if (health['fullScreenAllowed'] != true)
        healthProblem(
          context,
          l10n.fullScreenOff,
          l10n.fullScreenOffSubtitle,
          () => _telecom.openSystemSettings('fullScreen'),
        ),
      if (!_bluetoothNames)
        healthProblem(context, l10n.bluetoothNamesHidden, l10n.bluetoothNamesHiddenSubtitle, () async {
          await allowBluetoothNames();
          _refresh();
        }),
    ];
    return OneUIGroupCard(
      items: problems.isNotEmpty
          ? problems
          : [
              OneUIGroupItem(
                leading: const Icon(Icons.check_circle_rounded, color: answerGreen),
                title: l10n.onboardingAllSet,
              ),
            ],
    );
  }
}
