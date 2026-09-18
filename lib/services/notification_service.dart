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

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
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

  Future<void> cancelReminders(String cardId) async {
    final baseId = _baseIdFor(cardId);
    await _plugin.cancel(baseId);
    for (int i = 1; i <= _maxReminders; i++) {
      await _plugin.cancel(baseId + i);
    }
  }
}
