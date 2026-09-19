import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ciclo_teste_app/models/app_models.dart';
import 'package:ciclo_teste_app/models/time_models.dart';
import 'package:ciclo_teste_app/services/backup_service.dart';
import 'package:ciclo_teste_app/widgets/bug_badges.dart';

void main() {
  group('Sprint', () {
    test('sprints antigas sem status assumem "em andamento"', () {
      final s = Sprint.fromJson({'id': '1', 'name': 'Sprint 1'});
      expect(s.status, Sprint.statusEmAndamento);
      expect(s.concluida, isFalse);
    });

    test('status concluída é salvo e lido', () {
      final s = Sprint(id: '1', name: 'S', status: Sprint.statusConcluida);
      final back = Sprint.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.concluida, isTrue);
    });
  });

  group('fmtExecutado', () {
    final now = DateTime(2025, 5, 24, 15, 0);

    test('hoje', () {
      final t = DateTime(2025, 5, 24, 9, 30).millisecondsSinceEpoch;
      expect(fmtExecutado(t, now: now), 'Hoje, 09:30');
    });

    test('ontem', () {
      final t = DateTime(2025, 5, 23, 16, 40).millisecondsSinceEpoch;
      expect(fmtExecutado(t, now: now), 'Ontem, 16:40');
    });

    test('outro dia', () {
      final t = DateTime(2025, 5, 10, 14, 2).millisecondsSinceEpoch;
      expect(fmtExecutado(t, now: now), '10/05, 14:02');
    });
  });

  group('WorkActivity', () {
    test('progresso da checklist', () {
      final a = WorkActivity(id: 'a', name: 'X', items: [
        ChecklistItem(id: '1', text: 'a', done: true),
        ChecklistItem(id: '2', text: 'b'),
      ]);
      expect(a.doneCount, 1);
      expect(a.progress, 0.5);
    });

    test('tempo soma o acumulado e a sessão em andamento', () {
      final a = WorkActivity(
        id: 'a',
        name: 'X',
        totalMs: 60000,
        active: ActiveTimer(startedAt: 1000, accumulatedMs: 0, status: 'running'),
      );
      expect(a.elapsedMs(6000), 65000);
      expect(a.running, isTrue);
    });

    test('ida e volta em JSON preserva projeto e checklist', () {
      final a = WorkActivity(id: 'a', name: 'X', projectId: 'p1', items: [ChecklistItem(id: '1', text: 'a', done: true)]);
      final back = WorkActivity.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
      expect(back.projectId, 'p1');
      expect(back.items.single.done, isTrue);
    });
  });

  group('BackupService', () {
    test('formato novo restaura Ciclo de Teste e Atividades', () {
      final ciclo = AppState(projects: [ProjectItem(id: 'p', name: 'P')], currentProjectId: 'p');
      final tempo = TimeState(
        projects: [WorkProject(id: 'w', name: 'TCC')],
        days: [
          DayLog(dateKey: '2025-05-24', activities: [WorkActivity(id: 'a', name: 'X', projectId: 'w')]),
        ],
        settings: TimeSettings(idleAlertMinutes: 90),
      );
      final data = BackupService.parse(jsonEncode(BackupService.build(ciclo, tempo)));
      expect(data.ciclo!.projects.single.name, 'P');
      expect(data.atividades!.projects.single.name, 'TCC');
      expect(data.atividades!.days.single.activities.single.projectId, 'w');
      expect(data.atividades!.settings.idleAlertMinutes, 90);
    });

    test('backup antigo (só Ciclo de Teste) continua funcionando', () {
      final old = jsonEncode(AppState(projects: [ProjectItem(id: 'p', name: 'Antigo')]).toJson());
      final data = BackupService.parse(old);
      expect(data.ciclo!.projects.single.name, 'Antigo');
      expect(data.atividades, isNull);
    });

    test('arquivo inválido gera erro', () {
      expect(() => BackupService.parse('{"foo": 1}'), throwsFormatException);
    });
  });
}
