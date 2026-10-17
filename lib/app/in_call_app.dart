import 'package:flutter/material.dart';

import '../features/in_call/in_call_screen.dart';
import '../theme/one_ui_theme.dart';

class InCallApp extends StatelessWidget {
  const InCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme,
      scrollBehavior: OneUITheme.scrollBehavior,
      home: const InCallScreen(),
    );
  }
}
