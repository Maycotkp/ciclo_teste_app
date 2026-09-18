import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/notification_service.dart';
import '../state/app_provider.dart';
import 'painel_tab.dart';
import 'tabelas_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    _refreshNotifStatus();
  }

  Future<void> _refreshNotifStatus() async {
    final granted = await NotificationService().hasPermission();
    if (mounted) setState(() => _notifGranted = granted);
  }

  Future<void> _askNotifPermission() async {
    final granted = await NotificationService().requestPermission();
    if (mounted) setState(() => _notifGranted = granted);
  }

  Future<void> _exportJson(AppProvider app) async {
    final file = await app.exportJson();
    await Share.shareXFiles([XFile(file.path)], text: 'Backup do Cronômetro de Ciclo de Teste');
  }

  Future<void> _importJson(AppProvider app) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final content = await File(path).readAsString();

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: const Text(
            'Isso vai SUBSTITUIR todos os dados atuais (todos os projetos). Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await app.importJson(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao importar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (!app.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('⏱️ Ciclo de Teste'),
          actions: [
            IconButton(
              icon: Icon(_notifGranted ? Icons.notifications_active : Icons.notifications_off),
              tooltip: _notifGranted ? 'Notificações ativas' : 'Ativar notificações',
              onPressed: _notifGranted ? null : _askNotifPermission,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Exportar JSON',
              onPressed: () => _exportJson(app),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Importar JSON',
              onPressed: () => _importJson(app),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Painel'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Tabelas'),
            ],
          ),
        ),
        body: Column(
          children: [
            _ProjectBar(app: app),
            const Expanded(
              child: TabBarView(
                children: [
                  PainelTab(),
                  TabelasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectBar extends StatelessWidget {
  const _ProjectBar({required this.app});
  final AppProvider app;

  Future<void> _renameProject(BuildContext context) async {
    final controller = TextEditingController(text: app.currentProject.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear projeto'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name != null) app.renameProject(name);
  }

  Future<void> _confirmDeleteProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir projeto'),
        content: Text(
            'Excluir "${app.currentProject.name}" e TODAS as Sprints/Cards/Ciclos dentro dele?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) app.deleteCurrentProject();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF161D2E),
      child: Row(
        children: [
          const Icon(Icons.folder, size: 18, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: app.currentProject.id,
                items: app.state.projects
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (id) {
                  if (id != null) app.switchProject(id);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Renomear',
            onPressed: () => _renameProject(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Excluir projeto',
            color: app.state.projects.length <= 1 ? Colors.grey : Colors.redAccent,
            onPressed: app.state.projects.length <= 1 ? null : () => _confirmDeleteProject(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_box, size: 18),
            tooltip: 'Novo projeto',
            onPressed: app.addProject,
          ),
        ],
      ),
    );
  }
}
