import '../models/app_models.dart';
import 'json_store.dart';

class StorageService {
  static const String fileName = 'ciclo_teste_state.json';

  final JsonFileStore _store = JsonFileStore(fileName);

  Future<AppState?> load() async {
    final json = await _store.read();
    if (json == null) return null;
    try {
      return AppState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AppState state) => _store.write(state.toJson());
}
