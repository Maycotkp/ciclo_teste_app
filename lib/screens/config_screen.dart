import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../state/app_provider.dart';
import '../state/time_provider.dart';
import '../theme/pixel.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late int _minutes;
  bool _saved = false;
  bool _notifGranted = false;
  String _backupMsg = '';

  @override
  void initState() {
    super.initState();
    _minutes = context.read<TimeProvider>().state.settings.idleAlertMinutes;
    _refreshNotif();
  }

  Future<void> _refreshNotif() async {
    final granted = await NotificationService().hasPermission();
    if (mounted) setState(() => _notifGranted = granted);
  }

  Future<void> _askNotif() async {
    final granted = await NotificationService().requestPermission();
    if (mounted) setState(() => _notifGranted = granted);
  }

  void _setMinutes(int v) => setState(() {
        _minutes = v.clamp(5, 240).toInt();
        _saved = false;
      });

  void _save() {
    context.read<TimeProvider>().setIdleMinutes(_minutes);
    setState(() => _saved = true);
  }

  Future<void> _export() async {
    final app = context.read<AppProvider>();
    final time = context.read<TimeProvider>();
    try {
      final file = await BackupService.exportToFile(app.state, time.state);
      setState(() {
        _backupMsg = 'BACKUP PRONTO: CICLO DE TESTE (${app.state.projects.length} PROJ.) + '
            'ATIVIDADES (${time.state.projects.length} PROJ., ${time.totalActivities} ATIV., ${time.totalItems} ITENS DE CHECKLIST)';
      });
      await Share.shareXFiles([XFile(file.path)], text: 'Backup do Ciclo de Teste');
    } catch (e) {
      if (mounted) setState(() => _backupMsg = 'FALHA AO EXPORTAR: $e');
    }
  }

  Future<void> _import() async {
    final app = context.read<AppProvider>();
    final time = context.read<TimeProvider>();

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final path = result?.files.single.path;
    if (path == null) return;

    BackupData data;
    try {
      data = BackupService.parse(await File(path).readAsString());
    } catch (e) {
      if (mounted) setState(() => _backupMsg = 'FALHA AO IMPORTAR: ${e is FormatException ? e.message : e}');
      return;
    }
    if (!mounted) return;

    final parts = <String>[
      if (data.ciclo != null) 'CICLO DE TESTE (todos os projetos)',
      if (data.atividades != null) 'ATIVIDADES (projetos, tempos e checklists)',
    ];
    if (parts.isEmpty) {
      setState(() => _backupMsg = 'O ARQUIVO NÃO TEM DADOS PARA IMPORTAR.');
      return;
    }
    final ok = await pixelConfirm(
      context,
      'Isso vai SUBSTITUIR os dados atuais de: ${parts.join(' e ')}. Continuar?',
      confirmLabel: 'IMPORTAR',
    );
    if (!ok) return;

    if (data.ciclo != null) await app.applyState(data.ciclo!);
    if (data.atividades != null) {
      await time.applyState(data.atividades!);
      if (mounted) setState(() => _minutes = time.state.settings.idleAlertMinutes);
    }
    if (mounted) setState(() => _backupMsg = 'IMPORTADO COM SUCESSO: ${parts.join(' + ').toUpperCase()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
            decoration: const BoxDecoration(
              color: Px.header,
              border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
            ),
            child: Row(
              children: [
                PixelButton(icon: Icons.arrow_back, width: 44, tooltip: 'Voltar', onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONFIGURAÇÕES', style: Px.p(13, color: Px.cyan, height: 1)),
                      const SizedBox(height: 6),
                      Text('ALERTA E BACKUP', style: Px.v(19, color: Px.amber).copyWith(letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(14, 16, 14, 24 + MediaQuery.of(context).padding.bottom),
              children: [
                Text('LEMBRETES', style: Px.p(10, color: Px.yellow, height: 1.4)),
                const SizedBox(height: 10),
                PixelPanel(
                  border: Px.purple,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('ALERTAR SE UMA ATIVIDADE FICAR RODANDO POR MUITO TEMPO', style: Px.p(9, height: 1.8)),
                      const SizedBox(height: 8),
                      Text(
                        'Avisa com uma notificação, perguntando se você ainda está nessa atividade.',
                        style: Px.v(21, color: Px.muted, height: 1.15),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.black, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('INTERVALO DE ALERTA', style: Px.p(8, color: Px.cyan, height: 1)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                PixelButton(icon: Icons.remove, width: 52, height: 52, tooltip: 'Diminuir 5 minutos', onPressed: _minutes > 5 ? () => _setMinutes(_minutes - 5) : null),
                                Expanded(
                                  child: Container(
                                    height: 52,
                                    margin: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Color(0xFF05121A), boxShadow: [BoxShadow(color: Color(0xFF0E3A47), spreadRadius: 2)]),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('$_minutes', style: Px.v(42, color: Px.amber).copyWith(shadows: const [Shadow(color: Color(0x99FFB020), blurRadius: 6)])),
                                        const SizedBox(width: 8),
                                        Text('MIN', style: Px.p(8, color: Px.cyan, height: 1)),
                                      ],
                                    ),
                                  ),
                                ),
                                PixelButton(icon: Icons.add, width: 52, height: 52, tooltip: 'Aumentar 5 minutos', onPressed: _minutes < 240 ? () => _setMinutes(_minutes + 5) : null),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('ATALHOS', style: Px.p(8, color: Px.muted, height: 1)),
                      const SizedBox(height: 8),
                      Wrap(
                        children: [
                          for (final v in const [30, 60, 90, 120]) PixelChip('$v MIN', selected: _minutes == v, onTap: () => _setMinutes(v)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PixelPanel(
                  border: _notifGranted ? Px.green : Px.amber,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _notifGranted
                            ? 'OK · NOTIFICAÇÕES LIGADAS. O LEMBRETE USA AS NOTIFICAÇÕES LOCAIS DO ANDROID.'
                            : 'NOTIFICAÇÕES DESLIGADAS. SEM ELAS O LEMBRETE NÃO APARECE.',
                        style: Px.p(7, color: _notifGranted ? Px.green : Px.amber, height: 1.8),
                      ),
                      if (!_notifGranted) ...[
                        const SizedBox(height: 8),
                        PixelButton(label: 'ATIVAR NOTIFICAÇÕES', variant: PxVariant.amber, fontSize: 8, onPressed: _askNotif),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('BACKUP E DADOS', style: Px.p(10, color: Px.yellow, height: 1.4)),
                const SizedBox(height: 10),
                PixelPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Guarde uma cópia de tudo: Ciclo de Teste e Atividades (projetos, ciclos, tempos e checklists), ou traga um backup de volta.',
                        style: Px.v(21, color: Px.muted, height: 1.15),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: PixelButton(label: 'EXPORTAR', icon: Icons.download, iconSize: 16, variant: PxVariant.cyan, fontSize: 8, height: 52, onPressed: _export)),
                          const SizedBox(width: 4),
                          Expanded(child: PixelButton(label: 'IMPORTAR', icon: Icons.upload, iconSize: 16, variant: PxVariant.amber, fontSize: 8, height: 52, onPressed: _import)),
                        ],
                      ),
                      if (_backupMsg.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10, left: 2, right: 2),
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.black, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
                          child: Text(_backupMsg, style: Px.p(7, color: Px.green, height: 1.8)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PixelButton(
                  label: _saved ? 'SALVO!' : 'SALVAR ALTERAÇÕES',
                  icon: Icons.save,
                  variant: _saved ? PxVariant.cyan : PxVariant.green,
                  height: 52,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
