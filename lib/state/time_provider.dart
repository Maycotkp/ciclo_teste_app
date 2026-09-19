import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import '../models/time_models.dart';
import '../services/notification_service.dart';
import '../services/time_storage_service.dart';

const _uuid = Uuid();

/// Estado e regras do módulo Atividades (tempo trabalhado por dia).
class TimeProvider extends ChangeNotifier {
  final TimeStorageService _storage = TimeStorageService();
  final NotificationService _notifications = NotificationService();

  TimeState state = TimeState();
  bool loaded = false;

  DateTime selectedDate = _dateOnly(DateTime.now());
  String? filterProjectId; // null = todos os projetos
  String? focusActivityId;

  Timer? _ticker;
  String _lastTodayKey = dateKeyOf(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ---------------- Ciclo de vida ----------------
  Future<void> init() async {
    final loadedState = await _storage.load();
    if (loadedState != null) state = loadedState;
    _reconcile();
    loaded = true;
    _startTicker();
    _save(persistOnly: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final key = dateKeyOf(now);
    var changed = false;

    if (key != _lastTodayKey) {
      final wasViewingToday = dateKeyOf(selectedDate) == _lastTodayKey;
      _reconcile();
      _lastTodayKey = key;
      if (wasViewingToday) selectedDate = _dateOnly(now);
      changed = true;
    }

    if (_afterCutoff(now)) {
      final log = _logFor(key);
      if (log != null && !log.locked) {
        _lockDay(log, now.millisecondsSinceEpoch);
        changed = true;
      }
    }

    if (changed) _save();
    if (changed || _anyRunning()) notifyListeners();
  }

  bool _afterCutoff(DateTime now) => now.hour == 23 && now.minute >= 55;

  bool _anyRunning() => state.days.any((d) => d.activities.any((a) => a.running));

  /// Fecha dias passados que ficaram com atividade rodando (app fechado durante a noite):
  /// o tempo vai até 23:59:59 do dia em que ela começou e o dia fica travado.
  void _reconcile() {
    final todayKey = dateKeyOf(DateTime.now());
    for (final day in state.days) {
      if (day.dateKey == todayKey) continue;
      final date = parseDateKey(day.dateKey);
      final endOfDay = date == null
          ? DateTime.now().millisecondsSinceEpoch
          : DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
      _lockDay(day, endOfDay);
    }
  }

  void _lockDay(DayLog day, int endMs) {
    for (final a in day.activities) {
      if (a.running) _foldSession(a, endMs);
    }
    day.locked = true;
  }

  // ---------------- Consultas ----------------
  String get todayKey => dateKeyOf(DateTime.now());

  String get selectedKey => dateKeyOf(selectedDate);

  bool get isToday => selectedKey == todayKey;

  DayLog? _logFor(String key) {
    for (final d in state.days) {
      if (d.dateKey == key) return d;
    }
    return null;
  }

  DayLog? get selectedLog => _logFor(selectedKey);

  /// Só o dia de hoje, ainda aberto, aceita alterações.
  bool get isEditable {
    if (!isToday) return false;
    if (_afterCutoff(DateTime.now())) return false;
    return !(selectedLog?.locked ?? false);
  }

  bool get selectedLocked => !isEditable;

  List<WorkActivity> get visibleActivities {
    final all = selectedLog?.activities ?? const <WorkActivity>[];
    if (filterProjectId == null) return all;
    return all.where((a) => a.projectId == filterProjectId).toList();
  }

  int get visibleTotalMs {
    final now = DateTime.now().millisecondsSinceEpoch;
    return visibleActivities.fold<int>(0, (a, x) => a + x.elapsedMs(now));
  }

  WorkProject? projectById(String? id) {
    if (id == null) return null;
    for (final p in state.projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Dias que têm algum registro (marca no calendário).
  Set<String> get daysWithRecords =>
      state.days.where((d) => d.activities.isNotEmpty).map((d) => d.dateKey).toSet();

  WorkActivity? get heroActivity {
    final acts = selectedLog?.activities ?? const <WorkActivity>[];
    if (acts.isEmpty) return null;
    for (final a in acts) {
      if (a.running) return a;
    }
    if (focusActivityId != null) {
      for (final a in acts) {
        if (a.id == focusActivityId) return a;
      }
    }
    return acts.last;
  }

  int get totalItems => state.days.fold<int>(0, (a, d) => a + d.activities.fold<int>(0, (b, x) => b + x.items.length));

  int get totalActivities => state.days.fold<int>(0, (a, d) => a + d.activities.length);

  // ---------------- Navegação ----------------
  void selectDate(DateTime d) {
    selectedDate = _dateOnly(d);
    notifyListeners();
  }

  void goToday() {
    selectedDate = _dateOnly(DateTime.now());
    notifyListeners();
  }

  void setFilter(String? projectId) {
    filterProjectId = projectId;
    notifyListeners();
  }

  // ---------------- Projetos ----------------
  void addProject(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final p = WorkProject(id: _uuid.v4(), name: clean);
    state.projects.add(p);
    filterProjectId = p.id;
    _save();
  }

  void deleteProject(String id) {
    state.projects.removeWhere((p) => p.id == id);
    for (final d in state.days) {
      for (final a in d.activities) {
        if (a.projectId == id) a.projectId = null;
      }
    }
    if (filterProjectId == id) filterProjectId = null;
    _save();
  }

  void setActivityProject(String activityId, String? projectId) {
    if (!isEditable) return;
    final a = _activity(activityId);
    if (a == null) return;
    a.projectId = projectId;
    _save();
  }

  // ---------------- Cronômetro ----------------
  WorkActivity? _activity(String id) {
    for (final a in selectedLog?.activities ?? const <WorkActivity>[]) {
      if (a.id == id) return a;
    }
    return null;
  }

  DayLog _ensureTodayLog() {
    var log = _logFor(todayKey);
    if (log == null) {
      log = DayLog(dateKey: todayKey);
      state.days.add(log);
    }
    return log;
  }

  void _foldSession(WorkActivity a, int nowMs) {
    final s = a.active;
    if (s == null) return;
    final d = nowMs - s.startedAt;
    a.totalMs += d < 0 ? 0 : d;
    a.active = null;
    _notifications.cancelIdleReminders(a.id);
  }

  void _pauseAllExcept(DayLog log, String? keepId, int nowMs) {
    for (final a in log.activities) {
      if (a.id != keepId && a.running) _foldSession(a, nowMs);
    }
  }

  void _startSession(DayLog log, WorkActivity a) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pauseAllExcept(log, a.id, now);
    if (a.running) return;
    a.active = ActiveTimer(startedAt: now, accumulatedMs: 0, status: 'running');
    a.lastStartedAt = now;
    focusActivityId = a.id;
    _notifications.scheduleIdleReminders(a.id, a.name, state.settings.idleAlertMinutes);
  }

  /// Inicia uma atividade nova (ou retoma a do mesmo nome, no mesmo dia).
  void startNew(String name, {String category = ''}) {
    if (!isEditable) return;
    final log = _ensureTodayLog();
    final clean = name.trim().isEmpty ? 'Nova atividade' : name.trim();
    WorkActivity? existing;
    for (final a in log.activities) {
      if (a.name.toLowerCase() == clean.toLowerCase()) existing = a;
    }
    final activity = existing ??
        WorkActivity(
          id: _uuid.v4(),
          name: clean,
          category: category.trim().toUpperCase(),
          projectId: filterProjectId,
        );
    if (existing == null) log.activities.add(activity);
    _startSession(log, activity);
    _save();
  }

  void toggle(String activityId) {
    if (!isEditable) return;
    final log = selectedLog;
    final a = _activity(activityId);
    if (log == null || a == null) return;
    if (a.running) {
      _foldSession(a, DateTime.now().millisecondsSinceEpoch);
      focusActivityId = a.id;
    } else {
      _startSession(log, a);
    }
    _save();
  }

  void heroPlay() {
    final a = heroActivity;
    if (a != null && !a.running) toggle(a.id);
  }

  void heroPause() {
    final a = heroActivity;
    if (a != null && a.running) toggle(a.id);
  }

  // ---------------- Checklist ----------------
  void toggleExpanded(String activityId) {
    final a = _activity(activityId);
    if (a == null) return;
    a.expanded = !a.expanded;
    notifyListeners();
  }

  void toggleItem(String activityId, String itemId) {
    if (!isEditable) return;
    final a = _activity(activityId);
    if (a == null) return;
    for (final i in a.items) {
      if (i.id == itemId) i.done = !i.done;
    }
    _save();
  }

  void addItem(String activityId, String text) {
    if (!isEditable) return;
    final clean = text.trim();
    if (clean.isEmpty) return;
    final a = _activity(activityId);
    if (a == null) return;
    a.items.add(ChecklistItem(id: _uuid.v4(), text: clean));
    a.expanded = true;
    _save();
  }

  // ---------------- Configurações ----------------
  void setIdleMinutes(int minutes) {
    state.settings.idleAlertMinutes = minutes.clamp(5, 240).toInt();
    for (final d in state.days) {
      for (final a in d.activities) {
        if (a.running) {
          _notifications.scheduleIdleReminders(a.id, a.name, state.settings.idleAlertMinutes);
        }
      }
    }
    _save();
  }

  // ---------------- Backup ----------------
  Future<void> applyState(TimeState newState) async {
    for (final d in state.days) {
      for (final a in d.activities) {
        _notifications.cancelIdleReminders(a.id);
      }
    }
    state = newState;
    _reconcile();
    filterProjectId = null;
    focusActivityId = null;
    selectedDate = _dateOnly(DateTime.now());
    _save();
  }

  // ---------------- Persistência ----------------
  void _save({bool persistOnly = false}) {
    _storage.save(state);
    if (!persistOnly) notifyListeners();
  }
}
