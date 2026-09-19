// Smoke test: garante que o app inicializa sem lançar exceções.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciclo_teste_app/main.dart';

void main() {
  testWidgets('App inicializa e mostra a tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const CicloTesteApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
  });
}
