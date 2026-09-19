import 'app_models.dart';

String dateKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Projeto do módulo Atividades (lista própria, separada dos projetos do Ciclo de Teste).
class WorkProject {
  final String id;
  String name;

  WorkProject({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory WorkProject.fromJson(Map<String, dynamic> j) =>
      WorkProject(id: j['id'] as String, name: (j['name'] ?? 'Projeto') as String);
}

class ChecklistItem {
  final String id;
  String text;
  bool done;

  ChecklistItem({required this.id, required this.text, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        text: (j['text'] ?? '') as String,
        done: (j['done'] ?? false) as bool,
      );
}

/// Uma atividade de um dia. Enquanto [active] não é nulo, ela está rodando;
/// ao pausar, o tempo da sessão é somado em [totalMs].
class WorkActivity {
  final String id;
  String name;
  String category;
  String? projectId;
  int totalMs;
  int? lastStartedAt;
  ActiveTimer? active;
  List<ChecklistItem> items;

  /// Estado de tela (não é salvo).
  bool expanded = false;

  WorkActivity({
    required this.id,
    required this.name,
    this.category = '',
    this.projectId,
    this.totalMs = 0,
    this.lastStartedAt,
    this.active,
    List<ChecklistItem>? items,
  }) : items = items ?? [];

  bool get running => active != null;

  int elapsedMs([int? nowMs]) {
    final a = active;
    if (a == null) return totalMs;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final d = now - a.startedAt;
    return totalMs + (d < 0 ? 0 : d);
  }

  int get doneCount => items.where((i) => i.done).length;

  double get progress => items.isEmpty ? 0 : doneCount / items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'projectId': projectId,
        'totalMs': totalMs,
        'lastStartedAt': lastStartedAt,
        'active': active?.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory WorkActivity.fromJson(Map<String, dynamic> j) => WorkActivity(
        id: j['id'] as String,
        name: (j['name'] ?? 'Atividade') as String,
        category: (j['category'] ?? '') as String,
        projectId: j['projectId'] as String?,
        totalMs: (j['totalMs'] ?? 0) as int,
        lastStartedAt: j['lastStartedAt'] as int?,
        active: j['active'] != null ? ActiveTimer.fromJson(Map<String, dynamic>.from(j['active'])) : null,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((i) => ChecklistItem.fromJson(Map<String, dynamic>.from(i)))
            .toList(),
      );
}

class DayLog {
  final String dateKey;
  List<WorkActivity> activities;
  bool locked;

  DayLog({required this.dateKey, List<WorkActivity>? activities, this.locked = false})
      : activities = activities ?? [];

  int totalMs([int? nowMs]) => activities.fold<int>(0, (a, x) => a + x.elapsedMs(nowMs));

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'locked': locked,
        'activities': activities.map((a) => a.toJson()).toList(),
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        dateKey: j['dateKey'] as String,
        locked: (j['locked'] ?? false) as bool,
        activities: (j['activities'] as List<dynamic>? ?? [])
            .map((a) => WorkActivity.fromJson(Map<String, dynamic>.from(a)))
            .toList(),
      );
}

class TimeSettings {
  int idleAlertMinutes;

  TimeSettings({this.idleAlertMinutes = 60});

  Map<String, dynamic> toJson() => {'idleAlertMinutes': idleAlertMinutes};

  factory TimeSettings.fromJson(Map<String, dynamic> j) =>
      TimeSettings(idleAlertMinutes: ((j['idleAlertMinutes'] ?? 60) as int).clamp(5, 240).toInt());
}

class TimeState {
  List<WorkProject> projects;
  List<DayLog> days;
  TimeSettings settings;

  TimeState({List<WorkProject>? projects, List<DayLog>? days, TimeSettings? settings})
      : projects = projects ?? [],
        days = days ?? [],
        settings = settings ?? TimeSettings();

  Map<String, dynamic> toJson() => {
        'projects': projects.map((p) => p.toJson()).toList(),
        'days': days.map((d) => d.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory TimeState.fromJson(Map<String, dynamic> j) => TimeState(
        projects: (j['projects'] as List<dynamic>? ?? [])
            .map((p) => WorkProject.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        days: (j['days'] as List<dynamic>? ?? [])
            .map((d) => DayLog.fromJson(Map<String, dynamic>.from(d)))
            .toList(),
        settings: TimeSettings.fromJson(Map<String, dynamic>.from(j['settings'] ?? {})),
      );
}
