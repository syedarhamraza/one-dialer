import 'package:flutter/material.dart';

import 'app/dialer_app.dart';
import 'app/in_call_app.dart';

/// Main UI: dial pad, recents, contacts.
void main() => runApp(const DialerApp());

/// Runs on the pre-warmed engine started by `InCallEngine.kt` for the call screen.
@pragma('vm:entry-point')
void inCallMain() => runApp(const InCallApp());
