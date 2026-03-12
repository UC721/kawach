import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/app.dart';

void main() {
  testWidgets('KAWACH app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const KawachApp());

    expect(find.byType(KawachApp), findsOneWidget);
  });
}