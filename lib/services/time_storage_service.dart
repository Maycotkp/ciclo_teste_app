import '../models/time_models.dart';
import 'json_store.dart';

/// Guarda o módulo Atividades em um arquivo próprio, separado do Ciclo de Teste.
class TimeStorageService {
  static const String fileName = 'atividades_state.json';

  final JsonFileStore _store = JsonFileStore(fileName);

  Future<TimeState?> load() async {
    final json = await _store.read();
    if (json == null) return null;
    try {
      return TimeState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TimeState state) => _store.write(state.toJson());
}
