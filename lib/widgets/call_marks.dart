import 'package:flutter/material.dart';

/// A call's VoLTE mark: "Vo" over "LTE" (or "NR" for 5G voice), tiny, in [color]
/// (Recents, the call history and the call screen).
class VolteMark extends StatelessWidget {
  const VolteMark({super.key, required this.color, this.nr = false, this.fontSize = 6.5});

  final Color color;
  final bool nr;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, height: 1, fontWeight: FontWeight.w700, color: color);
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Vo', style: style),
          Text(nr ? 'NR' : 'LTE', style: style),
        ],
      ),
    );
  }
}
