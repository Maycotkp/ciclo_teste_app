import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/app_provider.dart';
import '../widgets/bug_badges.dart';
import '../widgets/finish_cycle_dialog.dart';

class PainelTab extends StatefulWidget {
  const PainelTab({super.key});

  @override
  State<PainelTab> createState() => _PainelTabState();
}

class _PainelTabState extends State<PainelTab> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final sprints = app.visibleSprints();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por sprint ou card...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: app.setMainSearch,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.unfold_more),
                tooltip: 'Expandir tudo',
                onPressed: () => app.setAllCollapsed(false),
              ),
              IconButton(
                icon: const Icon(Icons.unfold_less),
                tooltip: 'Recolher tudo',
                onPressed: () => app.setAllCollapsed(true),
              ),
            ],
          ),
        ),
        Expanded(
          child: sprints.isEmpty
              ? const _EmptyState(text: 'Nenhuma Sprint ainda. Toque em "Nova Sprint" para começar.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sprints.length,
                  itemBuilder: (ctx, i) => _SprintCard(sprint: sprints[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nova Sprint'),
              onPressed: app.addSprint,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ),
      );
}

class _SprintCard extends StatelessWidget {
  const _SprintCard({required this.sprint});
  final Sprint sprint;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final visibleCards = app.visibleCards(sprint);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => app.toggleSprintCollapse(sprint.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(sprint.collapsed ? Icons.chevron_right : Icons.expand_more),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('SPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: _InlineRename(
                        initialValue: sprint.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        onSubmit: (v) => app.renameSprint(sprint.id, v),
                      ),
                    ),
                  ),
                  Text('(${sprint.cards.length} cards)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined, size: 20),
                    tooltip: 'Novo card',
                    onPressed: () => app.addCard(sprint.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Excluir sprint',
                    onPressed: () async {
                      final ok = await _confirm(context, 'Excluir esta Sprint e todos os cards/ciclos dentro dela?');
                      if (ok) app.deleteSprint(sprint.id);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (!sprint.collapsed)
            if (visibleCards.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('Nenhum card nesta Sprint ainda.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...visibleCards.map((c) => _CardTile(sprint: sprint, card: c)),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
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
  return result ?? false;
}

class _InlineRename extends StatefulWidget {
  const _InlineRename({required this.initialValue, required this.onSubmit, this.style});
  final String initialValue;
  final ValueChanged<String> onSubmit;
  final TextStyle? style;

  @override
  State<_InlineRename> createState() => _InlineRenameState();
}

class _InlineRenameState extends State<_InlineRename> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void didUpdateWidget(covariant _InlineRename oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && !_focusHasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  final FocusNode _focus = FocusNode();
  bool get _focusHasFocus => _focus.hasFocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      style: widget.style,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
      onSubmitted: widget.onSubmit,
      onTapOutside: (_) {
        _focus.unfocus();
        widget.onSubmit(_controller.text);
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.sprint, required this.card});
  final Sprint sprint;
  final CardItem card;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isRunning = card.active?.status == 'running';
    final isPaused = card.active?.status == 'paused';
    final isIdle = card.active == null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2740),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3452)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => app.toggleCardCollapse(sprint.id, card.id),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(card.collapsed ? Icons.chevron_right : Icons.expand_more, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _InlineRename(
                      initialValue: card.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      onSubmit: (v) => app.renameCard(sprint.id, card.id, v),
                    ),
                  ),
                  Text('(${card.cycles.length} ciclos)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () async {
                      final ok = await _confirm(context, 'Excluir este card e todos os ciclos dele?');
                      if (ok) app.deleteCard(sprint.id, card.id);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (!card.collapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161D2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A3452)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmtTime(card.getElapsed()),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFF5B8CFF),
                            ),
                          ),
                          Text(
                            isRunning ? 'RODANDO' : (isPaused ? 'PAUSADO' : 'PARADO'),
                            style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    if (isIdle)
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Iniciar'),
                        onPressed: () => app.startCycle(sprint.id, card.id),
                      ),
                    if (isRunning)
                      IconButton.filled(
                        icon: const Icon(Icons.pause),
                        style: IconButton.styleFrom(backgroundColor: Colors.amber),
                        onPressed: () => app.pauseResume(sprint.id, card.id),
                      ),
                    if (isPaused)
                      IconButton.filled(
                        icon: const Icon(Icons.play_arrow),
                        style: IconButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => app.pauseResume(sprint.id, card.id),
                      ),
                    if (!isIdle) ...[
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Finalizar'),
                        onPressed: () async {
                          final result = await showFinishCycleDialog(context);
                          if (result != null) {
                            app.finishCycle(sprint.id, card.id, result.bugs, result.melhorias);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (card.cycles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  children: card.cycles.asMap().entries.map((entry) {
                    final i = entry.key;
                    final c = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 60, child: Text('Ciclo ${i + 1}', style: const TextStyle(fontSize: 12))),
                          SizedBox(width: 64, child: Text(fmtTime(c.elapsedMs), style: const TextStyle(fontSize: 12))),
                          Expanded(child: BugBadges(bugs: c.bugs)),
                          Text('${c.melhorias} melh.', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Text('Nenhum ciclo finalizado ainda.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}
