import 'package:flutter_test/flutter_test.dart';
import 'package:reposicao_app/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryPetsApp());
    expect(find.text("Delivery Pets"), findsOneWidget);
  });
}
