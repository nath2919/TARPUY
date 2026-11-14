import 'package:flutter_test/flutter_test.dart';

import 'package:rimana_ayni/main.dart';

void main() {
  testWidgets('shows the accessibility home screen with live camera and voice', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Rimana Ayni'), findsWidgets);
    expect(find.text('Cámara en vivo'), findsOneWidget);
    expect(find.text('Escuchar voz'), findsOneWidget);
    expect(find.text('Alfabeto en lengua de señas (español)'), findsOneWidget);
  });
}
