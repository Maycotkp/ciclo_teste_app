class Bugs {
  int critico;
  int bloqueado;
  int medio;
  int baixo;

  Bugs({this.critico = 0, this.bloqueado = 0, this.medio = 0, this.baixo = 0});

  int get total => critico + bloqueado + medio + baixo;

  Map<String, dynamic> toJson() => {
        'critico': critico,
        'bloqueado': bloqueado,
        'medio': medio,
        'baixo': baixo,
      };

  factory Bugs.fromJson(Map<String, dynamic> j) => Bugs(
        critico: (j['critico'] ?? 0) as int,
        bloqueado: (j['bloqueado'] ?? 0) as int,
        medio: (j['medio'] ?? 0) as int,
        baixo: (j['baixo'] ?? 0) as int,
      );
}

class Cycle {
  final String id;
  final int elapsedMs;
  final Bugs bugs;
  final int melhorias;
  final int finishedAt;

  Cycle({
    required this.id,
    required this.elapsedMs,
    required this.bugs,
    required this.melhorias,
    required this.finishedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'elapsedMs': elapsedMs,
        'bugs': bugs.toJson(),
        'melhorias': melhorias,
        'finishedAt': finishedAt,
      };

  factory Cycle.fromJson(Map<String, dynamic> j) => Cycle(
        id: j['id'] as String,
        elapsedMs: (j['elapsedMs'] ?? 0) as int,
        bugs: Bugs.fromJson(Map<String, dynamic>.from(j['bugs'] ?? {})),
        melhorias: (j['melhorias'] ?? 0) as int,
        finishedAt: (j['finishedAt'] ?? 0) as int,
      );
}

class ActiveTimer {
  int startedAt;
  int accumulatedMs;
  String status; // 'running' | 'paused'

  ActiveTimer({
    required this.startedAt,
    required this.accumulatedMs,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt,
        'accumulatedMs': accumulatedMs,
        'status': status,
      };

  factory ActiveTimer.fromJson(Map<String, dynamic> j) => ActiveTimer(
        startedAt: (j['startedAt'] ?? 0) as int,
        accumulatedMs: (j['accumulatedMs'] ?? 0) as int,
        status: (j['status'] ?? 'paused') as String,
      );

  int elapsed() {
    if (status == 'running') {
      return accumulatedMs + (DateTime.now().millisecondsSinceEpoch - startedAt);
    }
    return accumulatedMs;
  }
}

class CardItem {
  final String id;
  String name;
  bool collapsed;
  List<Cycle> cycles;
  ActiveTimer? active;

  CardItem({
    required this.id,
    required this.name,
    this.collapsed = false,
    List<Cycle>? cycles,
    this.active,
  }) : cycles = cycles ?? [];

  int getElapsed() => active?.elapsed() ?? 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'collapsed': collapsed,
        'cycles': cycles.map((c) => c.toJson()).toList(),
        'active': active?.toJson(),
      };

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
        id: j['id'] as String,
        name: (j['name'] ?? 'Card') as String,
        collapsed: (j['collapsed'] ?? false) as bool,
        cycles: (j['cycles'] as List<dynamic>? ?? [])
            .map((c) => Cycle.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        active: j['active'] != null
            ? ActiveTimer.fromJson(Map<String, dynamic>.from(j['active']))
            : null,
      );
}

class Sprint {
  static const statusEmAndamento = 'em_andamento';
  static const statusConcluida = 'concluida';

  final String id;
  String name;
  bool collapsed;
  String status; // 'em_andamento' | 'concluida' (definido manualmente)
  List<CardItem> cards;

  Sprint({
    required this.id,
    required this.name,
    this.collapsed = false,
    this.status = statusEmAndamento,
    List<CardItem>? cards,
  }) : cards = cards ?? [];

  bool get concluida => status == statusConcluida;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'collapsed': collapsed,
        'status': status,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory Sprint.fromJson(Map<String, dynamic> j) => Sprint(
        id: j['id'] as String,
        name: (j['name'] ?? 'Sprint') as String,
        collapsed: (j['collapsed'] ?? false) as bool,
        status: (j['status'] == statusConcluida) ? statusConcluida : statusEmAndamento,
        cards: (j['cards'] as List<dynamic>? ?? [])
            .map((c) => CardItem.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
      );
}

class ProjectItem {
  final String id;
  String name;
  List<Sprint> sprints;

  ProjectItem({required this.id, required this.name, List<Sprint>? sprints})
      : sprints = sprints ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sprints': sprints.map((s) => s.toJson()).toList(),
      };

  factory ProjectItem.fromJson(Map<String, dynamic> j) => ProjectItem(
        id: j['id'] as String,
        name: (j['name'] ?? 'Projeto') as String,
        sprints: (j['sprints'] as List<dynamic>? ?? [])
            .map((s) => Sprint.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
      );
}

class AppState {
  List<ProjectItem> projects;
  String? currentProjectId;

  AppState({required this.projects, this.currentProjectId});

  Map<String, dynamic> toJson() => {
        'projects': projects.map((p) => p.toJson()).toList(),
        'currentProjectId': currentProjectId,
      };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
        projects: (j['projects'] as List<dynamic>? ?? [])
            .map((p) => ProjectItem.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        currentProjectId: j['currentProjectId'] as String?,
      );

  factory AppState.empty() => AppState(projects: [], currentProjectId: null);
}
