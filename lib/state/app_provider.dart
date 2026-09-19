import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();

  AppState state = AppState.empty();
  bool loaded = false;

  // Busca/filtros do Painel
  String mainSearchTerm = '';

  // Filtros da tela Tabelas
  String tblSearch = '';
  String? tblSprintId;
  String? tblCardId;
  int? tblCycle;
  final Set<String> tblCollapsedSprints = {};
  final Set<String> tblCollapsedCards = {};

  Timer? _ticker;

  Future<void> init() async {
    await _notifications.init();
    final loadedState = await _storage.load();
    if (loadedState != null && loadedState.projects.isNotEmpty) {
      state = loadedState;
    } else {
      final p = ProjectItem(id: _uuid.v4(), name: 'Projeto 1');
      state = AppState(projects: [p], currentProjectId: p.id);
      await _storage.save(state);
    }
    if (state.currentProjectId == null ||
        !state.projects.any((p) => p.id == state.currentProjectId)) {
      state.currentProjectId = state.projects.first.id;
    }
    loaded = true;
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_anyRunning()) notifyListeners();
    });
  }

  bool _anyRunning() {
    for (final p in state.projects) {
      for (final s in p.sprints) {
        for (final c in s.cards) {
          if (c.active?.status == 'running') return true;
        }
      }
    }
    return false;
  }

  void _save() {
    _storage.save(state);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------------- Projeto ----------------
  ProjectItem get currentProject =>
      state.projects.firstWhere((p) => p.id == state.currentProjectId, orElse: () => state.projects.first);

  void addProject([String? name]) {
    final clean = name?.trim() ?? '';
    final p = ProjectItem(
      id: _uuid.v4(),
      name: clean.isEmpty ? 'Projeto ${state.projects.length + 1}' : clean,
    );
    state.projects.add(p);
    state.currentProjectId = p.id;
    mainSearchTerm = '';
    _save();
  }

  void switchProject(String projectId) {
    state.currentProjectId = projectId;
    mainSearchTerm = '';
    tblSearch = '';
    tblSprintId = null;
    tblCardId = null;
    tblCycle = null;
    notifyListeners();
  }

  void renameProject(String name) {
    if (name.trim().isEmpty) return;
    currentProject.name = name.trim();
    _save();
  }

  void deleteCurrentProject() {
    if (state.projects.length <= 1) return;
    final p = currentProject;
    for (final s in p.sprints) {
      for (final c in s.cards) {
        _notifications.cancelReminders(c.id);
      }
    }
    state.projects.removeWhere((x) => x.id == p.id);
    state.currentProjectId = state.projects.first.id;
    _save();
  }

  // ---------------- Sprint ----------------
  void addSprint() {
    final project = currentProject;
    project.sprints.add(Sprint(id: _uuid.v4(), name: 'Sprint ${project.sprints.length + 1}'));
    _save();
  }

  Sprint? findSprint(String sprintId) {
    try {
      return currentProject.sprints.firstWhere((s) => s.id == sprintId);
    } catch (_) {
      return null;
    }
  }

  CardItem? findCard(String sprintId, String cardId) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return null;
    try {
      return sprint.cards.firstWhere((c) => c.id == cardId);
    } catch (_) {
      return null;
    }
  }

  void deleteSprint(String sprintId) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return;
    for (final c in sprint.cards) {
      _notifications.cancelReminders(c.id);
    }
    currentProject.sprints.removeWhere((s) => s.id == sprintId);
    _save();
  }

  void renameSprint(String sprintId, String name) {
    final sprint = findSprint(sprintId);
    if (sprint == null || name.trim().isEmpty) return;
    sprint.name = name.trim();
    _save();
  }

  void setSprintStatus(String sprintId, String status) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return;
    sprint.status = status == Sprint.statusConcluida ? Sprint.statusConcluida : Sprint.statusEmAndamento;
    _save();
  }

  void toggleSprintCollapse(String sprintId) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return;
    sprint.collapsed = !sprint.collapsed;
    _save();
  }

  // ---------------- Card ----------------
  void addCard(String sprintId) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return;
    sprint.cards.add(CardItem(id: _uuid.v4(), name: 'Card ${sprint.cards.length + 1}'));
    _save();
  }

  void deleteCard(String sprintId, String cardId) {
    final sprint = findSprint(sprintId);
    if (sprint == null) return;
    _notifications.cancelReminders(cardId);
    sprint.cards.removeWhere((c) => c.id == cardId);
    _save();
  }

  void renameCard(String sprintId, String cardId, String name) {
    final card = findCard(sprintId, cardId);
    if (card == null || name.trim().isEmpty) return;
    card.name = name.trim();
    _save();
  }

  void toggleCardCollapse(String sprintId, String cardId) {
    final card = findCard(sprintId, cardId);
    if (card == null) return;
    card.collapsed = !card.collapsed;
    _save();
  }

  void setAllCollapsed(bool collapsed) {
    for (final s in currentProject.sprints) {
      s.collapsed = collapsed;
      for (final c in s.cards) {
        c.collapsed = collapsed;
      }
    }
    _save();
  }

  // ---------------- Ciclo ----------------
  void startCycle(String sprintId, String cardId) {
    final card = findCard(sprintId, cardId);
    if (card == null || card.active != null) return;
    card.active = ActiveTimer(
      startedAt: DateTime.now().millisecondsSinceEpoch,
      accumulatedMs: 0,
      status: 'running',
    );
    _save();
    _notifications.notifyNow(card.id, card.name, '0s');
    _notifications.scheduleReminders(card.id, card.name);
  }

  void pauseResume(String sprintId, String cardId) {
    final card = findCard(sprintId, cardId);
    if (card == null || card.active == null) return;
    final active = card.active!;
    if (active.status == 'running') {
      active.accumulatedMs += DateTime.now().millisecondsSinceEpoch - active.startedAt;
      active.status = 'paused';
      _notifications.cancelReminders(card.id);
    } else {
      active.startedAt = DateTime.now().millisecondsSinceEpoch;
      active.status = 'running';
      _notifications.scheduleReminders(card.id, card.name);
    }
    _save();
  }

  void finishCycle(String sprintId, String cardId, Bugs bugs, int melhorias) {
    final card = findCard(sprintId, cardId);
    if (card == null || card.active == null) return;
    _notifications.cancelReminders(card.id);
    final elapsed = card.getElapsed();
    card.cycles.add(Cycle(
      id: _uuid.v4(),
      elapsedMs: elapsed,
      bugs: bugs,
      melhorias: melhorias,
      finishedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    card.active = null;
    _save();
  }

  // ---------------- Export / Import ----------------
  Future<void> applyState(AppState newState) async {
    for (final p in state.projects) {
      for (final s in p.sprints) {
        for (final c in s.cards) {
          _notifications.cancelReminders(c.id);
        }
      }
    }
    if (newState.projects.isEmpty) {
      newState.projects.add(ProjectItem(id: _uuid.v4(), name: 'Projeto 1'));
    }
    if (newState.currentProjectId == null ||
        !newState.projects.any((p) => p.id == newState.currentProjectId)) {
      newState.currentProjectId = newState.projects.first.id;
    }
    state = newState;
    _save();
  }

  // ---------------- Filtros / busca (setters seguros) ----------------
  void setMainSearch(String v) {
    mainSearchTerm = v;
    notifyListeners();
  }

  void setTblSearch(String v) {
    tblSearch = v;
    notifyListeners();
  }

  void setTblSprintId(String? v) {
    tblSprintId = v;
    tblCardId = null;
    notifyListeners();
  }

  void setTblCardId(String? v) {
    tblCardId = v;
    notifyListeners();
  }

  void setTblCycle(int? v) {
    tblCycle = v;
    notifyListeners();
  }

  void clearTblFilters() {
    tblSearch = '';
    tblSprintId = null;
    tblCardId = null;
    tblCycle = null;
    notifyListeners();
  }

  void toggleTblSprintCollapse(String sprintId) {
    if (!tblCollapsedSprints.remove(sprintId)) tblCollapsedSprints.add(sprintId);
    notifyListeners();
  }

  void toggleTblCardCollapse(String cardId) {
    if (!tblCollapsedCards.remove(cardId)) tblCollapsedCards.add(cardId);
    notifyListeners();
  }

  // ---------------- Helpers de visão (Painel) ----------------
  List<CardItem> visibleCards(Sprint sprint) {
    final term = mainSearchTerm.trim().toLowerCase();
    if (term.isEmpty) return sprint.cards;
    if (sprint.name.toLowerCase().contains(term)) return sprint.cards;
    return sprint.cards.where((c) => c.name.toLowerCase().contains(term)).toList();
  }

  List<Sprint> visibleSprints() {
    final term = mainSearchTerm.trim().toLowerCase();
    if (term.isEmpty) return currentProject.sprints;
    return currentProject.sprints.where((s) => visibleCards(s).isNotEmpty).toList();
  }
}
