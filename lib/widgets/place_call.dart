import 'package:flutter/material.dart';

import '../core/contacts/contacts_repository.dart';
import '../core/prefs/dialer_prefs.dart';
import '../core/telecom/call_info.dart';
import '../core/telecom/telecom_bridge.dart';
import '../theme/one_ui_theme.dart';

/// Calls [number] the way Samsung does: on [simId] if given, else on the contact's chosen
/// SIM, else (dual SIM with "Ask every time") after asking with our own SIM sheet.
Future<void> placeCall(BuildContext context, String number, {String? simId}) async {
  final telecom = TelecomBridge.instance;
  if (simId == null) {
    final contact = ContactsRepository.instance.contactFor(number);
    if (contact != null) simId = await DialerPrefs.instance.contactSim(contact.id);
  }
  if (simId == null) {
    final sims = await telecom.getSims();
    if (sims.length > 1 && !sims.any((s) => s.isDefault)) {
      if (!context.mounted) return;
      final sim = await _pickSim(context, sims);
      if (sim == null) return;
      simId = sim.id;
    }
  }
  await telecom.placeCall(number, simId: simId);
}

Future<SimCard?> _pickSim(BuildContext context, List<SimCard> sims) => showModalBottomSheet<SimCard>(
      context: context,
      backgroundColor: OneUITheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OneUITheme.radiusCard)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Call using', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final sim in sims)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OneUITheme.accentGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: () => Navigator.of(context).pop(sim),
                          icon: const Icon(Icons.call_rounded),
                          label: Text(sim.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
