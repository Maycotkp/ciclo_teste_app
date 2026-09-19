import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/app_provider.dart';
import '../theme/pixel.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final sprints = app.visibleSprints();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _ProjectPanel(app: app),
        const SizedBox(height: 8),
        PixelTextField(
          controller: _searchController,
          hint: 'BUSCAR SPRINT OU CARD...',
          icon: Icons.search,
          ringColor: Px.cyan,
          onChanged: app.setMainSearch,
        ),
        Row(
          children: [
            Expanded(
              child: PixelButton(
                label: 'EXPANDIR',
                icon: Icons.unfold_more,
                iconSize: 16,
                fontSize: 8,
                height: 38,
                onPressed: () => app.setAllCollapsed(false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: PixelButton(
                label: 'RECOLHER',
                icon: Icons.unfold_less,
                iconSize: 16,
                fontSize: 8,
                height: 38,
                onPressed: () => app.setAllCollapsed(true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sprints.isEmpty)
          PixelPanel(
            border: Px.amber,
            padding: const EdgeInsets.all(14),
            child: Text(
              app.mainSearchTerm.isEmpty
                  ? 'NENHUMA SPRINT AINDA. TOQUE EM NOVA SPRINT PARA COMEÇAR.'
                  : 'NENHUM RESULTADO PARA A BUSCA.',
              style: Px.p(8, color: Px.amber, height: 1.8),
            ),
          )
        else
          for (final s in sprints) _SprintCard(sprint: s),
        const SizedBox(height: 8),
        PixelButton(label: 'NOVA SPRINT', icon: Icons.add, variant: PxVariant.purple, height: 48, onPressed: app.addSprint),
      ],
    );
  }
}

class _ProjectPanel extends StatelessWidget {
  const _ProjectPanel({required this.app});
  final AppProvider app;

  Future<void> _pick(BuildContext context) async {
    final id = await showPixelDialog<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TROCAR DE PROJETO', style: Px.p(11, color: Px.cyan, height: 1.6)),
          const SizedBox(height: 10),
          for (final p in app.state.projects)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: PixelChip(
                p.name.toUpperCase(),
                selected: p.id == app.currentProject.id,
                onTap: () => Navigator.pop(ctx, p.id),
              ),
            ),
        ],
      ),
    );
    if (id != null) app.switchProject(id);
  }

  Future<void> _create(BuildContext context) async {
    final name = await pixelPrompt(context, title: 'NOVO PROJETO', hint: 'NOME DO PROJETO');
    if (name != null) app.addProject(name);
  }

  Future<void> _rename(BuildContext context) async {
    final name = await pixelPrompt(
      context,
      title: 'RENOMEAR PROJETO',
      hint: 'NOME DO PROJETO',
      initial: app.currentProject.name,
      confirmLabel: 'SALVAR',
    );
    if (name != null) app.renameProject(name);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await pixelConfirm(
      context,
      'Excluir "${app.currentProject.name}" e TODAS as Sprints, Cards e Ciclos dentro dele?',
    );
    if (ok) app.deleteCurrentProject();
  }

  @override
  Widget build(BuildContext context) {
    final only = app.state.projects.length <= 1;
    return PixelPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pick(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJETO', style: Px.p(8, color: Px.violet, height: 1)),
                  const SizedBox(height: 7),
                  Text(
                    app.currentProject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Px.p(10, color: Px.cyan, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
          PixelButton(icon: Icons.expand_more, width: 36, height: 36, padding: EdgeInsets.zero, tooltip: 'Trocar de projeto', onPressed: () => _pick(context)),
          PixelButton(icon: Icons.edit, iconSize: 14, width: 36, height: 36, padding: EdgeInsets.zero, tooltip: 'Renomear projeto', onPressed: () => _rename(context)),
          PixelButton(
            icon: Icons.delete_outline,
            iconSize: 16,
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
            variant: PxVariant.red,
            tooltip: 'Excluir projeto',
            onPressed: only ? null : () => _delete(context),
          ),
          PixelButton(label: '+ NOVO', variant: PxVariant.cyan, fontSize: 8, height: 36, onPressed: () => _create(context)),
        ],
      ),
    );
  }
}

class _SprintCard extends StatelessWidget {
  const _SprintCard({required this.sprint});
  final Sprint sprint;

  Future<void> _pickStatus(BuildContext context, AppProvider app) async {
    final status = await showPixelDialog<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('STATUS DA SPRINT', style: Px.p(11, color: Px.cyan, height: 1.6)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: PixelChip('EM ANDAMENTO', selected: !sprint.concluida, onTap: () => Navigator.pop(ctx, Sprint.statusEmAndamento)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: PixelChip('CONCLUÍDA', selected: sprint.concluida, onTap: () => Navigator.pop(ctx, Sprint.statusConcluida)),
          ),
        ],
      ),
    );
    if (status != null) app.setSprintStatus(sprint.id, status);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final visibleCards = app.visibleCards(sprint);
    final done = sprint.concluida;

    return PixelPanel(
      border: done ? Px.line : Px.purple,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PixelBadge('SPRINT', bg: done ? Px.line2 : Px.purple, fg: done ? Px.muted : Colors.white),
              const SizedBox(width: 4),
              PixelBadge(
                done ? 'CONCLUÍDA' : 'EM ANDAMENTO',
                trailing: Icons.expand_more,
                bg: done ? const Color(0xFF0F3D27) : const Color(0xFF0B3A4A),
                fg: done ? Px.green : Px.cyan,
                ring: done ? Px.green : Px.cyan,
                onTap: () => _pickStatus(context, app),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InlineRename(
                  key: ValueKey('sprint-${sprint.id}'),
                  initialValue: sprint.name,
                  style: Px.p(11, color: done ? Px.muted : Px.yellow, height: 1.5),
                  onSubmit: (v) => app.renameSprint(sprint.id, v),
                ),
              ),
              PixelButton(
                icon: Icons.add,
                iconSize: 16,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                variant: PxVariant.cyan,
                tooltip: 'Novo card',
                onPressed: () => app.addCard(sprint.id),
              ),
              PixelButton(
                icon: Icons.delete_outline,
                iconSize: 16,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                variant: PxVariant.red,
                tooltip: 'Excluir sprint',
                onPressed: () async {
                  final ok = await pixelConfirm(context, 'Excluir esta Sprint e todos os cards e ciclos dentro dela?');
                  if (ok) app.deleteSprint(sprint.id);
                },
              ),
              PixelButton(
                icon: sprint.collapsed ? Icons.expand_more : Icons.expand_less,
                iconSize: 18,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                tooltip: sprint.collapsed ? 'Expandir sprint' : 'Recolher sprint',
                onPressed: () => app.toggleSprintCollapse(sprint.id),
              ),
            ],
          ),
          Text('${sprint.cards.length} cards', style: Px.v(19, color: Px.muted)),
          if (!sprint.collapsed) ...[
            const SizedBox(height: 10),
            if (visibleCards.isEmpty)
              Text('Nenhum card nesta Sprint ainda.', style: Px.v(20, color: Px.muted))
            else
              for (final c in visibleCards) _CardTile(sprint: sprint, card: c),
          ],
        ],
      ),
    );
  }
}

class _InlineRename extends StatefulWidget {
  const _InlineRename({super.key, required this.initialValue, required this.onSubmit, this.style});
  final String initialValue;
  final ValueChanged<String> onSubmit;
  final TextStyle? style;

  @override
  State<_InlineRename> createState() => _InlineRenameState();
}

class _InlineRenameState extends State<_InlineRename> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _InlineRename oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && !_focus.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      style: widget.style,
      cursorColor: Px.cyan,
      cursorWidth: 3,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
      onSubmitted: widget.onSubmit,
      onTapOutside: (_) {
        if (_focus.hasFocus) {
          _focus.unfocus();
          widget.onSubmit(_controller.text);
        }
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.sprint, required this.card});
  final Sprint sprint;
  final CardItem card;

  Future<void> _finish(BuildContext context, AppProvider app) async {
    final active = card.active;
    if (active == null) return;
    // Congela o tempo enquanto a janela está aberta.
    final wasRunning = active.status == 'running';
    if (wasRunning) app.pauseResume(sprint.id, card.id);
    final result = await showFinishCycleDialog(
      context,
      cycleNumber: card.cycles.length + 1,
      elapsedMs: card.getElapsed(),
    );
    if (result != null) {
      app.finishCycle(sprint.id, card.id, result.bugs, result.melhorias);
    } else if (wasRunning) {
      app.pauseResume(sprint.id, card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final status = card.active?.status;
    final isRunning = status == 'running';
    final isPaused = status == 'paused';
    final isIdle = card.active == null;

    final Color stateColor = isRunning ? Px.green : (isPaused ? Px.amber : const Color(0xFF7DD3FC));
    final String stateLabel = isRunning ? 'EM ANDAMENTO' : (isPaused ? 'PAUSADO' : 'PARADO');

    return PixelPanel(
      border: isIdle ? Px.line : Px.cyan,
      fill: Px.panelDark,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => app.toggleCardCollapse(sprint.id, card.id),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(card.collapsed ? Icons.chevron_right : Icons.expand_more, size: 22, color: Px.cyan),
                ),
              ),
              Expanded(
                child: _InlineRename(
                  key: ValueKey('card-${card.id}'),
                  initialValue: card.name,
                  style: Px.p(10, height: 1.5),
                  onSubmit: (v) => app.renameCard(sprint.id, card.id, v),
                ),
              ),
              PixelButton(
                icon: Icons.delete_outline,
                iconSize: 15,
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                variant: PxVariant.red,
                tooltip: 'Excluir card',
                onPressed: () async {
                  final ok = await pixelConfirm(context, 'Excluir este card e todos os ciclos dele?');
                  if (ok) app.deleteCard(sprint.id, card.id);
                },
              ),
            ],
          ),
          if (card.collapsed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${card.cycles.length} ciclos · $stateLabel',
                style: Px.v(19, color: isIdle ? Px.muted : stateColor),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              decoration: const BoxDecoration(
                color: Colors.black,
                boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: stateColor),
                      const SizedBox(width: 7),
                      Text('CICLO #${card.cycles.length + 1} · $stateLabel', style: Px.p(8, color: stateColor, height: 1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      fmtTime(card.getElapsed()),
                      style: Px.v(66, color: stateColor).copyWith(
                        letterSpacing: 2,
                        shadows: [Shadow(color: stateColor, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Os 3 botões ficam sempre visíveis; o que não se aplica ao estado fica apagado.
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: isPaused ? 'RETOMAR' : 'INICIAR',
                    variant: PxVariant.green,
                    fontSize: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onPressed: isRunning
                        ? null
                        : () => isIdle ? app.startCycle(sprint.id, card.id) : app.pauseResume(sprint.id, card.id),
                  ),
                ),
                Expanded(
                  child: PixelButton(
                    label: 'PAUSAR',
                    variant: PxVariant.purple,
                    fontSize: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onPressed: isRunning ? () => app.pauseResume(sprint.id, card.id) : null,
                  ),
                ),
                Expanded(
                  child: PixelButton(
                    label: 'FINALIZAR',
                    variant: PxVariant.red,
                    fontSize: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onPressed: isIdle ? null : () => _finish(context, app),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (card.cycles.isEmpty)
              Text('Nenhum ciclo finalizado ainda.', style: Px.v(20, color: Px.muted))
            else ...[
              Row(
                children: [
                  Expanded(child: Text('CICLOS CONCLUÍDOS (${card.cycles.length})', style: Px.p(8, color: Px.muted, height: 1.4))),
                  Text(fmtTime(card.cycles.fold<int>(0, (a, c) => a + c.elapsedMs)), style: Px.v(22, color: Px.cyan)),
                ],
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < card.cycles.length; i++) _CycleRow(index: i + 1, cycle: card.cycles[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.index, required this.cycle});
  final int index;
  final Cycle cycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Px.header, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('CICLO #$index', style: Px.p(8, color: Px.yellow, height: 1)),
              const SizedBox(width: 8),
              Expanded(child: Text(fmtExecutado(cycle.finishedAt), style: Px.v(17, color: Px.muted))),
              Text(fmtTime(cycle.elapsedMs), style: Px.v(21, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          BugBadges(bugs: cycle.bugs, melhorias: cycle.melhorias),
        ],
      ),
    );
  }
}
