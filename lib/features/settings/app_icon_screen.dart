import 'package:flutter/material.dart';

import '../../core/telecom/telecom_bridge.dart';
import '../../l10n/l10n.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/showcase_picker.dart';

/// Settings › More settings › App icon: the Phone and Contacts launcher icons switch together
/// (AppIcons.kt). Previews are rendered by tool/icons/render_icons.py.
class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  static Map<String, String> labels(AppLocalizations l10n) => {
    'default': l10n.appIconGlossy,
    'classic': l10n.appIconClassic,
  };

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  final _style = ValueNotifier('default');

  @override
  void initState() {
    super.initState();
    TelecomBridge.instance.getLauncherIcon().then((s) {
      if (mounted) _style.value = s;
    });
  }

  @override
  void dispose() {
    _style.dispose();
    super.dispose();
  }

  void _pick(String style) {
    _style.value = style;
    TelecomBridge.instance.setLauncherIcon(style);
  }

  @override
  Widget build(BuildContext context) => CosSubpage(
    title: context.l10n.appIcon,
    children: [
      ShowcasePicker(
        value: _style,
        onPick: _pick,
        footnote: context.l10n.appIconFootnote,
        options: [
          for (final MapEntry(key: style, value: label) in AppIconScreen.labels(context.l10n).entries)
            ShowcaseOption(
              value: style,
              label: label,
              preview: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_Tile(style, 'phone'), const SizedBox(width: 12), _Tile(style, 'contacts')],
              ),
            ),
        ],
      ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.style, this.app);

  final String style;
  final String app;

  @override
  Widget build(BuildContext context) => ClipRRect(
    // About the rounding launchers give the adaptive icon's tile.
    borderRadius: BorderRadius.circular(16),
    child: Image.asset('assets/app_icons/${style}_$app.png', width: 56, height: 56, filterQuality: FilterQuality.medium),
  );
}
