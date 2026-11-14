import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';
import '../l10n/l10n.dart';

/// Samsung One UI 9 Signature Floating Modal Container & Dialog System.
///
/// Matches Samsung One UI Reference Screenshots 1:1:
/// - 16dp margins on left, right, and bottom.
/// - 28dp fully rounded corners.
/// - Dynamic 3D elevation / rim highlight or clean flat appearance based on OneUIEffectsController.
/// - Standard "Cancel  |  Action" footer.
class OneUIFloatingModal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const OneUIFloatingModal({super.key, required this.child, this.padding});

  static final ValueNotifier<bool> isModalOpen = ValueNotifier<bool>(false);

  /// Shows a generic One UI floating modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) async {
    isModalOpen.value = true;
    try {
      return await showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: isScrollControlled,
        useRootNavigator: true,
        builder: (ctx) => OneUIFloatingModal(child: builder(ctx)),
      );
    } finally {
      isModalOpen.value = false;
    }
  }

  /// Shows a modal dialog with a text input field, managing its controller lifecycle safely.
  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    String? message,
    String initialValue = '',
    String? prefixText,
    String? cancelLabel,
    String? confirmLabel,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = true,
  }) async {
    isModalOpen.value = true;
    try {
      return await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (ctx) => _OneUIFloatingTextInputModal(
          title: title,
          message: message,
          initialValue: initialValue,
          prefixText: prefixText,
          cancelLabel: cancelLabel ?? context.l10n.cancel,
          confirmLabel: confirmLabel ?? context.l10n.save,
          keyboardType: keyboardType,
          autofocus: autofocus,
        ),
      );
    } finally {
      isModalOpen.value = false;
    }
  }

  /// Shows a One UI Signature Confirmation / Action Dialog matching Screenshot 1:1
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? message,
    Widget? customContent,
    String? cancelLabel,
    String? confirmLabel,
    Color? confirmTextColor,
    VoidCallback? onConfirm,
  }) async {
    isModalOpen.value = true;
    try {
      return await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (ctx) => OneUIFloatingModal(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              // Optional Message Body
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 15.5, color: Color(0xFFC4C4CA), height: 1.35, letterSpacing: -0.2),
                ),
              ],

              // Optional Custom Content (e.g. text inputs)
              if (customContent != null) ...[const SizedBox(height: 16), customContent],

              const SizedBox(height: 20),

              // Footer: Cancel  |  Confirm
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: SquircleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        cancelLabel ?? context.l10n.cancel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 18, color: context.palette.divider),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx, true);
                        onConfirm?.call();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: SquircleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        confirmLabel ?? context.l10n.delete,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: confirmTextColor ?? context.palette.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } finally {
      isModalOpen.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboardInset),
            child: Material(
              color: Colors.transparent,
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                elevation: OneUIGlassElevation.modal,
                duration: const Duration(milliseconds: 200),
                padding: padding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OneUIFloatingTextInputModal extends StatefulWidget {
  final String title;
  final String? message;
  final String initialValue;
  final String? prefixText;
  final String cancelLabel;
  final String confirmLabel;
  final TextInputType keyboardType;
  final bool autofocus;

  const _OneUIFloatingTextInputModal({
    required this.title,
    this.message,
    required this.initialValue,
    this.prefixText,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.keyboardType,
    required this.autofocus,
  });

  @override
  State<_OneUIFloatingTextInputModal> createState() => _OneUIFloatingTextInputModalState();
}

class _OneUIFloatingTextInputModalState extends State<_OneUIFloatingTextInputModal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OneUIFloatingModal(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: const TextStyle(fontSize: 15.5, color: Color(0xFFC4C4CA), height: 1.35, letterSpacing: -0.2),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            decoration: BoxDecoration(color: context.palette.pill, borderRadius: OneUITheme.fieldBorderRadius),
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              style: TextStyle(color: context.palette.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: widget.prefixText,
                prefixStyle: TextStyle(color: context.palette.textPrimary, fontSize: 18),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: SquircleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.cancelLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 18, color: context.palette.divider),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, _controller.text.trim()),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: SquircleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.confirmLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
