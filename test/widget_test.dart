import 'package:flutter_test/flutter_test.dart';
import 'package:super_cajon/main.dart';

void main() {
  testWidgets('exibe a identidade do Super Cajon na abertura', (tester) async {
    await tester.pumpWidget(const SuperCajonApp(initializePurchases: false));

    expect(find.text('CAJÓN PRONTO PARA TOCAR'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
