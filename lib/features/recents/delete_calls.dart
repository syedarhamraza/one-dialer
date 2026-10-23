import 'package:flutter/material.dart';

import '../../widgets/cos_dialog.dart';
import '../../widgets/one_ui_toast.dart';
import 'call_log_repository.dart';

/// Shared confirmation and error handling; the repository updates every list immediately.
Future<bool> confirmDeleteCalls(BuildContext context, Iterable<int> ids, {VoidCallback? onConfirmed}) async {
  final records = ids.toSet();
  if (records.isEmpty) return false;
  final ok = await showCosConfirm(
    context,
    title: records.length == 1 ? 'Delete call?' : 'Delete ${records.length} calls?',
    message: 'The selected call history will be removed from this phone.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  onConfirmed?.call();
  try {
    await CallLogRepository.instance.delete(records);
    return true;
  } catch (_) {
    if (context.mounted) OneUIToast.show(context, "Couldn't delete call history. Try again.");
    return false;
  }
}
