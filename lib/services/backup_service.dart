import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';
import '../models/time_models.dart';

/// Conteúdo lido de um arquivo de backup. Cada parte é nula quando o arquivo não a traz
/// (ex.: backups antigos só têm o Ciclo de Teste).
class BackupData {
  BackupData({this.ciclo, this.atividades});

  final AppState? ciclo;
  final TimeState? atividades;
}

/// Backup único com as duas áreas do app: Ciclo de Teste e Atividades.
class BackupService {
  static const int version = 2;

  static Map<String, dynamic> build(AppState ciclo, TimeState atividades) => {
        'version': version,
        'exportedAt': DateTime.now().toIso8601String(),
        'ciclo': ciclo.toJson(),
        'atividades': atividades.toJson(),
      };

  static Future<File> exportToFile(AppState ciclo, TimeState atividades) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/ciclo-teste-backup-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(build(ciclo, atividades)));
    return file;
  }

  static BackupData parse(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo inválido.');
    }

    // Formato novo (v2): duas seções.
    if (decoded['ciclo'] is Map || decoded['atividades'] is Map) {
      return BackupData(
        ciclo: decoded['ciclo'] is Map ? AppState.fromJson(Map<String, dynamic>.from(decoded['ciclo'])) : null,
        atividades:
            decoded['atividades'] is Map ? TimeState.fromJson(Map<String, dynamic>.from(decoded['atividades'])) : null,
      );
    }

    // Formato antigo: só o Ciclo de Teste, na raiz.
    if (decoded['projects'] is List) {
      return BackupData(ciclo: AppState.fromJson(decoded));
    }

    throw const FormatException('Formato inválido: não é um backup do Ciclo de Teste.');
  }
}
