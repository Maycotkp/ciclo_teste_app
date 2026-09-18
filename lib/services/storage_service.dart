import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class StorageService {
  static const String fileName = 'ciclo_teste_state.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<AppState?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (e) {
      // Arquivo corrompido ou indisponível: começa do zero em vez de travar o app.
      return null;
    }
  }

  Future<void> save(AppState state) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      // Falha silenciosa: perder uma gravação pontual não deve derrubar o app.
    }
  }

  Future<File> exportToFile(AppState state) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/ciclo-teste-backup-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(state.toJson()));
    return file;
  }

  AppState parseImport(String content) {
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    if (decoded['projects'] is List) {
      return AppState.fromJson(decoded);
    }
    throw const FormatException('Formato inválido: não contém "projects".');
  }
}
