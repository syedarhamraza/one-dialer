import 'package:dialer/widgets/one_ui_radio.dart';
import 'package:dialer/widgets/showcase_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/l10n/app_localizations.dart';

void main() {
  testWidgets('tapping an option picks it and moves the radio', (tester) async {
    final value = ValueNotifier('banner');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShowcasePicker(
            value: value,
            onPick: (v) => value.value = v,
            footnote: 'Only while unlocked.',
            options: const [
              ShowcaseOption(
                value: 'banner',
                label: 'Banner',
                preview: PhonePreview(child: SizedBox()),
              ),
              ShowcaseOption(
                value: 'full',
                label: 'Full screen',
                preview: PhonePreview(child: SizedBox()),
              ),
            ],
          ),
        ),
      ),
    );
    bool selected(int i) => tester.widgetList<OneUIRadio>(find.byType(OneUIRadio)).elementAt(i).isSelected;
    expect([selected(0), selected(1)], [true, false]);
    expect(find.text('Only while unlocked.'), findsOneWidget);

    await tester.tap(find.byType(PhonePreview).last);
    await tester.pump();
    expect(value.value, 'full');
    expect([selected(0), selected(1)], [false, true]);
  });
}
