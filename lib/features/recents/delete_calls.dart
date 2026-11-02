import 'package:flutter/material.dart';

import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_toast.dart';
import 'call_log_repository.dart';
import '../../l10n/l10n.dart';

/// Shared confirmation and error handling; the repository updates every list immediately.
Future<bool> confirmDeleteCalls(BuildContext context, Iterable<int> ids, {VoidCallback? onConfirmed}) async {
  final records = ids.toSet();
  if (records.isEmpty) return false;
  final ok = await showCosConfirm(
    context,
    title: context.l10n.deleteCallsTitle(records.length),
    message: context.l10n.deleteCallsMessage,
    confirmLabel: context.l10n.delete,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  onConfirmed?.call();
  try {
    await CallLogRepository.instance.delete(records);
    return true;
  } catch (_) {
    if (context.mounted) OneUIToast.show(context, context.l10n.couldNotDeleteCalls);
    return false;
  }
}
