import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/call_info.dart';
import '../core/telecom/telecom_bridge.dart';
import '../l10n/l10n.dart';
import 'one_ui_floating_menu.dart';
import 'one_ui_toast.dart';

/// Calls [number] the way Samsung does: on [simId] if given, else on the contact's chosen
/// SIM, else (dual SIM with "Ask every time") after asking with our SIM menu, which pops
/// from [anchorKey]'s button (or [anchorContext]'s widget) when given. [chooseSim] always asks on dual SIM.
/// False when no call was placed: the SIM menu was dismissed, or Android refused (a toast says so).
Future<bool> placeCall(
  BuildContext context,
  String number, {
  String? simId,
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
  bool chooseSim = false,
}) async {
  final telecom = TelecomBridge.instance;
  if (chooseSim) {
    final sims = await telecom.getSims();
    if (sims.length > 1) {
      if (!context.mounted) return false;
      final sim = await pickSim(context, sims, anchorKey: anchorKey, anchorContext: anchorContext);
      if (sim == null) return false;
      simId = sim.id;
    }
  }
  if (simId == null) {
    final contact = ContactsRepository.instance.contactFor(number);
    if (contact != null) simId = await DialerPrefs.instance.contactSim(contact.id);
  }
  if (simId == null) {
    final sims = await telecom.getSims();
    if (sims.length > 1 && !sims.any((s) => s.isDefault)) {
      if (!context.mounted) return false;
      final sim = await pickSim(context, sims, anchorKey: anchorKey, anchorContext: anchorContext);
      if (sim == null) return false;
      simId = sim.id;
    }
  }
  // The page may have closed during the lookups above; the call still goes out, and only the toast needs the page.
  final placed = await _placed(() => telecom.placeCall(number, simId: simId));
  if (!placed && context.mounted) OneUIToast.show(context, context.l10n.couldNotPlaceCall);
  return placed;
}

/// Calls back call-log row [id] through the app that logged it (WhatsApp...).
Future<bool> callBackRow(BuildContext context, int id) async {
  final placed = await _placed(() => TelecomBridge.instance.callBack(id));
  if (!placed && context.mounted) OneUIToast.show(context, context.l10n.couldNotPlaceCall);
  return placed;
}

/// False when Android refused the call (the Phone permission was taken away): the caller says so
/// with a toast, so it never looks like a dead button.
Future<bool> _placed(Future<void> Function() call) async {
  try {
    await call();
    return true;
  } on PlatformException {
    return false;
  }
}

/// The shared SIM menu; null when it's dismissed.
Future<SimCard?> pickSim(
  BuildContext context,
  List<SimCard> sims, {
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
}) async {
  final picked = Completer<SimCard?>();
  await OneUIFloatingMenu.show(
    context: context,
    anchorKey: anchorKey,
    anchorContext: anchorContext,
    centered: true,
    fallbackBottom: 120,
    width: 220,
    items: [
      for (final (i, sim) in sims.indexed)
        OneUIFloatingMenuItem(
          // Carrier names get the slot in front; SIMs already named "SIM n" don't repeat it.
          label: sim.label == 'SIM ${i + 1}' ? sim.label : 'SIM ${i + 1} · ${sim.label}',
          icon: Icons.sim_card_rounded,
          onTap: () => picked.complete(sim),
        ),
    ],
  );
  // The menu calls the item's onTap right after it closes, so a pick has landed by now.
  return picked.isCompleted ? picked.future : null;
}
