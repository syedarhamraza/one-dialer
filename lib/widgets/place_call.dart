import 'dart:async';

import 'package:flutter/material.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/call_info.dart';
import '../core/telecom/telecom_bridge.dart';
import 'one_ui_floating_menu.dart';

/// Calls [number] the way Samsung does: on [simId] if given, else on the contact's chosen
/// SIM, else (dual SIM with "Ask every time") after asking with our SIM menu, which pops
/// from [anchorKey]'s button (or [anchorContext]'s widget) when given. [chooseSim] always asks on dual SIM.
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
      final sim = await _pickSim(context, sims, anchorKey, anchorContext);
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
      final sim = await _pickSim(context, sims, anchorKey, anchorContext);
      if (sim == null) return false;
      simId = sim.id;
    }
  }
  await telecom.placeCall(number, simId: simId);
  return true;
}

Future<SimCard?> _pickSim(
  BuildContext context,
  List<SimCard> sims,
  GlobalKey? anchorKey,
  BuildContext? anchorContext,
) async {
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
