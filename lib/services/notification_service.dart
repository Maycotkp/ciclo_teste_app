import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Lembra o usuário de que um ciclo continua aberto/rodando.
/// Agenda um lote de lembretes futuros (a cada 20 min, por até 4h) quando um
/// ciclo inicia/retoma, e cancela todos quando ele é pausado/finalizado.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _reminderIntervalMinutes = 20;
  static const int _maxReminders = 12; // até 4h de lembretes futuros

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      // mantém UTC como fallback se a timezone local não puder ser resolvida
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);
    } catch (_) {
      // Fora do Android (testes, desktop) não há plugin de notificação: o app segue sem lembretes.
    }
    _initialized = true;
  }

  Future<bool> hasPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  int _baseIdFor(String cardId) => cardId.hashCode & 0x7fffffff;

  Future<void> notifyNow(String cardId, String cardName, String elapsedText) async {
    if (!await hasPermission()) return;
    await _plugin.show(
      _baseIdFor(cardId),
      '⏱️ Ciclo em andamento',
      '"$cardName" está rodando há $elapsedText. Não esqueça de finalizar!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ciclo_aberto',
          'Ciclo em andamento',
          channelDescription: 'Lembretes de ciclos de teste ainda abertos',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Agenda lembretes futuros (não recalcula o tempo decorrido; usa uma
  /// mensagem genérica, já que o app pode estar fechado quando disparar).
  Future<void> scheduleReminders(String cardId, String cardName) async {
    if (!await hasPermission()) return;
    await init();
    final baseId = _baseIdFor(cardId);

    for (int i = 1; i <= _maxReminders; i++) {
      final id = baseId + i;
      final when = tz.TZDateTime.now(tz.local).add(
        Duration(minutes: _reminderIntervalMinutes * i),
      );
      await _plugin.zonedSchedule(
        id,
        '⏱️ Ciclo ainda aberto',
        '"$cardName" continua rodando. Não esqueça de finalizar o ciclo!',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ciclo_aberto',
            'Ciclo em andamento',
            channelDescription: 'Lembretes de ciclos de teste ainda abertos',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static const int _maxIdleReminders = 8;

  static const NotificationDetails _idleDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'atividade_longa',
      'Atividade rodando há muito tempo',
      channelDescription: 'Pergunta se você ainda está numa atividade que continua rodando',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Agenda o alerta de "você ainda está nessa atividade?" a cada
  /// [intervalMinutes] enquanto a atividade continuar rodando.
  Future<void> scheduleIdleReminders(String activityId, String activityName, int intervalMinutes) async {
    if (!await hasPermission()) return;
    await init();
    await cancelIdleReminders(activityId);
    final baseId = _baseIdFor('idle-$activityId');
    for (int i = 1; i <= _maxIdleReminders; i++) {
      final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: intervalMinutes * i));
      await _plugin.zonedSchedule(
        baseId + i,
        '⏱️ Você ainda está nessa atividade?',
        '"$activityName" continua rodando. Pause se já terminou.',
        when,
        _idleDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelIdleReminders(String activityId) async {
    final baseId = _baseIdFor('idle-$activityId');
    try {
      for (int i = 1; i <= _maxIdleReminders; i++) {
        await _plugin.cancel(baseId + i);
      }
    } catch (_) {
      // Sem plugin de notificação (fora do Android): nada a cancelar.
    }
  }

  Future<void> cancelReminders(String cardId) async {
    final baseId = _baseIdFor(cardId);
    try {
      await _plugin.cancel(baseId);
      for (int i = 1; i <= _maxReminders; i++) {
        await _plugin.cancel(baseId + i);
      }
    } catch (_) {
      // Sem plugin de notificação (fora do Android): nada a cancelar.
    }
  }
}
