import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/billing/tips.dart';
import '../../l10n/l10n.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/cos_subpage.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_toast.dart';

/// Settings › Support One Dialer: the app is free; anyone who wants to can leave a tip.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<ProductDetails>? _tips; // null while loading
  late final StreamSubscription<TipResult> _results;

  @override
  void initState() {
    super.initState();
    _results = Tips.instance.results.stream.listen(_onResult);
    Tips.instance.load().then((tips) => mounted ? setState(() => _tips = tips) : null, onError: (_) {
      if (mounted) setState(() => _tips = const []);
    });
  }

  @override
  void dispose() {
    _results.cancel();
    super.dispose();
  }

  void _onResult(TipResult result) {
    if (!mounted) return;
    final l10n = context.l10n;
    OneUIToast.show(context, switch (result) {
      TipResult.thanks => l10n.tipThanks,
      TipResult.pending => l10n.tipPending,
      TipResult.failed => l10n.tipFailed,
    }, long: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tips = _tips;
    final names = {'tip_small': l10n.tipSmall, 'tip_medium': l10n.tipMedium, 'tip_large': l10n.tipLarge};
    return CosSubpage(
      title: l10n.supportOneDialer,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text(
            l10n.supportIntro,
            style: TextStyle(fontSize: 14.5, height: 1.4, color: context.palette.textSecondary),
          ),
        ),
        OneUIGroupCard(
          headerTitle: l10n.leaveATip,
          items: [
            if (tips == null)
              OneUIGroupItem(
                title: l10n.tipsLoading,
                enabled: false,
                trailing: const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (tips.isEmpty)
              OneUIGroupItem(title: l10n.tipsUnavailable, enabled: false, trailing: const SizedBox.shrink())
            else
              for (final tip in tips)
                OneUIGroupItem(
                  title: names[tip.id] ?? tip.title,
                  value: tip.price,
                  onTap: () => Tips.instance.buy(tip),
                ),
          ],
        ),
      ],
    );
  }
}
