import 'package:flutter_test/flutter_test.dart';

import 'package:ciclo_teste_app/models/app_models.dart';
import 'package:ciclo_teste_app/models/time_models.dart';
import 'package:ciclo_teste_app/state/time_provider.dart';

void main() {
  late TimeProvider time;

  setUp(() {
    time = TimeProvider();
    addTearDown(time.dispose);
  });

  test('só uma atividade roda por vez', () {
    time.startNew('Primeira');
    time.startNew('Segunda');
    final acts = time.selectedLog!.activities;
    expect(acts.length, 2);
    expect(acts.where((a) => a.running).length, 1);
    expect(acts.last.running, isTrue);
  });

  test('atividade com o mesmo nome no mesmo dia é retomada, não duplicada', () {
    time.startNew('Estudar');
    time.toggle(time.selectedLog!.activities.first.id); // pausa
    time.startNew('estudar'); // retoma
    expect(time.selectedLog!.activities.length, 1);
    expect(time.selectedLog!.activities.first.running, isTrue);
  });

  test('projeto do filtro vira o projeto da atividade nova, e é opcional', () {
    time.startNew('Sem projeto');
    time.addProject('TCC');
    final projectId = time.state.projects.single.id;
    expect(time.filterProjectId, projectId);
    time.startNew('Com projeto');
    final acts = time.selectedLog!.activities;
    expect(acts.first.projectId, isNull);
    expect(acts.last.projectId, projectId);
    time.setActivityProject(acts.first.id, projectId);
    expect(acts.first.projectId, projectId);
  });

  test('checklist: adicionar, marcar e progresso', () {
    time.startNew('Com checklist');
    final a = time.selectedLog!.activities.single;
    time.addItem(a.id, 'Item 1');
    time.addItem(a.id, 'Item 2');
    time.addItem(a.id, '   '); // vazio é ignorado
    expect(a.items.length, 2);
    time.toggleItem(a.id, a.items.first.id);
    expect(a.progress, 0.5);
  });

  test('dia encerrado não aceita itens, marcação, troca de projeto nem cronômetro', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final act = WorkActivity(
      id: 'a1',
      name: 'Antiga',
      totalMs: 1000,
      items: [ChecklistItem(id: 'i1', text: 'Feito antes', done: true)],
    );
    time.state.days.add(DayLog(dateKey: dateKeyOf(yesterday), activities: [act], locked: true));
    time.selectDate(yesterday);

    expect(time.isEditable, isFalse);
    time.addItem('a1', 'Novo item');
    time.toggleItem('a1', 'i1');
    time.setActivityProject('a1', 'qualquer');
    time.toggle('a1');
    time.startNew('Outra');

    expect(act.items.length, 1);
    expect(act.items.single.done, isTrue);
    expect(act.projectId, isNull);
    expect(act.running, isFalse);
    expect(time.state.days.length, 1);
  });

  test('ao abrir o app, atividade que ficou rodando em dia passado é encerrada às 23:59:59 e o dia trava', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 0, 0).millisecondsSinceEpoch;
    final act = WorkActivity(
      id: 'a1',
      name: 'Esquecida',
      active: ActiveTimer(startedAt: start, accumulatedMs: 0, status: 'running'),
    );
    time.state = TimeState(days: [DayLog(dateKey: dateKeyOf(yesterday), activities: [act])]);

    await time.init();

    expect(act.running, isFalse);
    expect(act.totalMs, const Duration(hours: 3, minutes: 59, seconds: 59).inMilliseconds);
    expect(time.state.days.single.locked, isTrue);
  });

  test('intervalo do alerta respeita os limites de 5 a 240 minutos', () {
    time.setIdleMinutes(1);
    expect(time.state.settings.idleAlertMinutes, 5);
    time.setIdleMinutes(999);
    expect(time.state.settings.idleAlertMinutes, 240);
    time.setIdleMinutes(90);
    expect(time.state.settings.idleAlertMinutes, 90);
  });
}
