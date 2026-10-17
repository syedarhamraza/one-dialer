import 'package:dialer/theme/one_ui_scroll.dart';
import 'package:dialer/widgets/one_ui_big_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('big title shows open, small title shows once collapsed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(
        physics: OneUIScrollPhysics.bigHeader,
        slivers: [
          const SliverPersistentHeader(pinned: true, delegate: OneUIBigHeader(title: 'Phone', subtitle: 'Sub')),
          SliverToBoxAdapter(child: SizedBox(height: 2000)),
        ],
      ),
    ));

    expect(find.text('Phone'), findsOneWidget); // big title only
    expect(find.text('Sub'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Phone'), findsOneWidget); // small title only
    expect(find.text('Sub'), findsNothing);
  });
}
