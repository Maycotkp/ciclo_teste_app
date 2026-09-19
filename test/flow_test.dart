// Percorre as telas principais no tamanho de um celular e falha se algum widget lançar erro
// (inclusive estouro de layout).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciclo_teste_app/main.dart';
import 'package:ciclo_teste_app/screens/atividades_tab.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await _settle(tester);
  await tester.tap(f);
  await _settle(tester);
}

/// Carrega as fontes do app para o teste medir o texto como no celular (sem isso o teste usa fonte quadrada).
Future<void> _loadFonts() async {
  const fonts = {
    'PressStart': 'assets/fonts/PressStart2P-Regular.ttf',
    'VT323': 'assets/fonts/VT323-Regular.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key)..addFont(rootBundle.load(e.value));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('navega por Painel, Tabelas, Atividades e Configurações', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CicloTesteApp());
    for (var i = 0; i < 30 && find.text('PAINEL').evaluate().isEmpty; i++) {
      await _settle(tester);
    }

    // Painel: cria sprint e card, inicia o ciclo.
    expect(find.text('PAINEL'), findsWidgets);
    await _tap(tester, find.text('NOVA SPRINT'));
    expect(find.text('EM ANDAMENTO'), findsOneWidget);

    await _tap(tester, find.byTooltip('Novo card'));
    expect(find.text('INICIAR'), findsWidgets);
    await _tap(tester, find.text('INICIAR').first);
    expect(find.textContaining('CICLO #1 · EM ANDAMENTO'), findsOneWidget);

    // Finalizar abre a janela com as prioridades.
    await _tap(tester, find.text('FINALIZAR'));
    expect(find.text('FINALIZAR CICLO #1'), findsOneWidget);
    await _tap(tester, find.byTooltip('Aumentar Crítico'));
    await _tap(tester, find.text('CONCLUIR'));
    expect(find.textContaining('CICLO #1'), findsWidgets);

    // Tabelas.
    await _tap(tester, find.text('TABELAS'));
    expect(find.textContaining('EXECUTADO EM'), findsWidgets);

    // Atividades: cria projeto, inicia atividade, cria checklist.
    await _tap(tester, find.text('ATIVIDADES').last);
    final scroll = find.descendant(of: find.byType(AtividadesTab), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('NOVA ATIVIDADE'), 300, scrollable: scroll);
    expect(find.text('NOVA ATIVIDADE'), findsOneWidget);

    final field = find.descendant(of: find.byType(AtividadesTab), matching: find.byType(TextField)).first;
    await tester.enterText(field, 'Estudar');
    await _tap(tester, find.descendant(of: find.byType(AtividadesTab), matching: find.text('INICIAR')));
    expect(find.text('RODANDO'), findsWidgets);

    await tester.scrollUntilVisible(find.byTooltip('Expandir checklist'), 300, scrollable: scroll);
    await _tap(tester, find.byTooltip('Expandir checklist'));
    expect(find.text('CHECKLIST (OPCIONAL)'), findsOneWidget);

    // Configurações.
    await _tap(tester, find.byTooltip('Configurações'));
    expect(find.text('BACKUP E DADOS'), findsOneWidget);
    expect(find.text('EXPORTAR'), findsOneWidget);
    expect(find.text('IMPORTAR'), findsOneWidget);

    // Desmonta a árvore para encerrar os timers dos providers.
    await tester.pumpWidget(const SizedBox());
  });
}
