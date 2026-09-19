import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Guarda um mapa JSON em um arquivo do armazenamento interno do app.
class JsonFileStore {
  JsonFileStore(this.fileName);

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      // Arquivo corrompido ou indisponível: começa do zero em vez de travar o app.
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> json) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(json));
    } catch (_) {
      // Perder uma gravação pontual não deve derrubar o app.
    }
  }
}
