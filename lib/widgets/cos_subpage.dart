import 'package:flutter/material.dart';

import 'one_ui_subpage.dart';

/// A ColorOS 17 subpage with fixed content: [OneUISubpage] without a builder.
class CosSubpage extends StatelessWidget {
  const CosSubpage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => OneUISubpage(title: title, builder: (_) => children);
}
