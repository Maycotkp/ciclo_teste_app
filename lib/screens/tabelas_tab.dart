import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/app_provider.dart';
import '../theme/pixel.dart';
import '../widgets/bug_badges.dart';
import '../widgets/charts.dart';

class _SprintRow {
  final String cardName;
  final int index;
  final int elapsedMs;
  final Bugs bugs;
  final int melhorias;
  final int finishedAt;
  _SprintRow(this.cardName, this.index, this.elapsedMs, this.bugs, this.melhorias, this.finishedAt);
}

class TabelasTab extends StatefulWidget {
  const TabelasTab({super.key});

  @override
  State<TabelasTab> createState() => _TabelasTabState();
}

class _TabelasTabState extends State<TabelasTab> {
  final _searchController = TextEditingController();
  final _cycleController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _cycleController.dispose();
    super.dispose();
  }

  List<_SprintRow> _rows(List<CardItem> cards, int? cycleFilter) {
    final rows = <_SprintRow>[];
    for (final card in cards) {
      for (int i = 0; i < card.cycles.length; i++) {
        final idx = i + 1;
        if (cycleFilter != null && idx != cycleFilter) continue;
        final c = card.cycles[i];
        rows.add(_SprintRow(card.name, idx, c.elapsedMs, c.bugs, c.melhorias, c.finishedAt));
      }
    }
    rows.sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
    return rows;
  }

  void _clearFilters(AppProvider app) {
    app.clearTblFilters();
    _searchController.clear();
    _cycleController.clear();
  }

  Future<void> _pickSprint(BuildContext context, AppProvider app) async {
    final options = <MapEntry<String?, String>>[
      const MapEntry(null, 'TODAS AS SPRINTS'),
      ...app.currentProject.sprints.map((s) => MapEntry<String?, String>(s.id, s.name.toUpperCase())),
    ];
    final picked = await _pickOption(context, 'FILTRAR POR SPRINT', options, app.tblSprintId);
    if (picked != null) app.setTblSprintId(picked.key);
  }

  Future<void> _pickCard(BuildContext context, AppProvider app, List<MapEntry<String, String>> cards) async {
    final options = <MapEntry<String?, String>>[
      const MapEntry(null, 'TODOS OS CARDS'),
      ...cards.map((e) => MapEntry<String?, String>(e.key, e.value.toUpperCase())),
    ];
    final picked = await _pickOption(context, 'FILTRAR POR CARD', options, app.tblCardId);
    if (picked != null) app.setTblCardId(picked.key);
  }

  /// Devolve a opção escolhida (envelopada, para diferenciar "nenhum" de "cancelou").
  Future<MapEntry<String?, String>?> _pickOption(
    BuildContext context,
    String title,
    List<MapEntry<String?, String>> options,
    String? current,
  ) {
    return showPixelDialog<MapEntry<String?, String>>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Px.p(11, color: Px.cyan, height: 1.6)),
              const SizedBox(height: 10),
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: PixelChip(o.value, selected: o.key == current, onTap: () => Navigator.pop(ctx, o)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final project = app.currentProject;
    final term = app.tblSearch.trim().toLowerCase();

    final cardOptions = <MapEntry<String, String>>[]; // id -> rótulo
    for (final s in project.sprints) {
      if (app.tblSprintId != null && s.id != app.tblSprintId) continue;
      for (final c in s.cards) {
        cardOptions.add(MapEntry(c.id, app.tblSprintId != null ? c.name : '${s.name} / ${c.name}'));
      }
    }
    if (app.tblCardId != null && !cardOptions.any((e) => e.key == app.tblCardId)) {
      app.tblCardId = null;
    }

    final sprintLabel = project.sprints.where((s) => s.id == app.tblSprintId).map((s) => s.name).firstOrNull ?? 'Todas';
    final cardLabel = cardOptions.where((e) => e.key == app.tblCardId).map((e) => e.value).firstOrNull ?? 'Todos';

    final groups = <Widget>[];
    for (final sprint in project.sprints) {
      if (app.tblSprintId != null && sprint.id != app.tblSprintId) continue;
      final matchingCards = sprint.cards.where((c) {
        if (app.tblCardId != null && c.id != app.tblCardId) return false;
        if (term.isNotEmpty && !(sprint.name.toLowerCase().contains(term) || c.name.toLowerCase().contains(term))) {
          return false;
        }
        return true;
      }).toList();
      if (matchingCards.isEmpty) continue;

      groups.add(_SprintGroup(
        sprint: sprint,
        matchingCards: matchingCards,
        rows: _rows(matchingCards, app.tblCycle),
        cycleFilter: app.tblCycle,
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        PixelPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('FILTROS · ${project.name.toUpperCase()}', style: Px.p(8, color: Px.violet, height: 1.5)),
              const SizedBox(height: 6),
              PixelTextField(
                controller: _searchController,
                hint: 'BUSCAR CARD OU SPRINT...',
                icon: Icons.search,
                ringColor: Px.cyan,
                onChanged: app.setTblSearch,
              ),
              Row(
                children: [
                  Expanded(child: _PickerField(label: 'SPRINT', value: sprintLabel, onTap: () => _pickSprint(context, app))),
                  const SizedBox(width: 6),
                  Expanded(child: _PickerField(label: 'CARD', value: cardLabel, onTap: () => _pickCard(context, app, cardOptions))),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: PixelTextField(
                      controller: _cycleController,
                      hint: 'Nº CICLO',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => app.setTblCycle(int.tryParse(v)),
                    ),
                  ),
                  const Spacer(),
                  PixelButton(label: 'LIMPAR', variant: PxVariant.red, fontSize: 8, height: 44, onPressed: () => _clearFilters(app)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          PixelPanel(
            border: Px.amber,
            padding: const EdgeInsets.all(14),
            child: Text('NENHUM RESULTADO PARA OS FILTROS SELECIONADOS.', style: Px.p(8, color: Px.amber, height: 1.8)),
          )
        else
          ...groups,
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Px.panelDark, boxShadow: Px.ring(Px.line)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Px.p(7, color: Px.muted, height: 1)),
                      const SizedBox(height: 7),
                      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Px.p(8, height: 1.2)),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more, size: 18, color: Px.cyan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SprintGroup extends StatelessWidget {
  const _SprintGroup({required this.sprint, required this.matchingCards, required this.rows, required this.cycleFilter});
  final Sprint sprint;
  final List<CardItem> matchingCards;
  final List<_SprintRow> rows;
  final int? cycleFilter;

  Bugs _sumBugs(List<_SprintRow> rows) {
    final b = Bugs();
    for (final r in rows) {
      b.critico += r.bugs.critico;
      b.bloqueado += r.bugs.bloqueado;
      b.medio += r.bugs.medio;
      b.baixo += r.bugs.baixo;
    }
    return b;
  }

  Widget _stat(String label, String value, Color color) {
    return PixelPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Px.p(7, color: Px.muted, height: 1)),
          const SizedBox(height: 10),
          Text(value, style: Px.v(30, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final collapsed = app.tblCollapsedSprints.contains(sprint.id);
    final done = sprint.concluida;
    final totalMelhorias = rows.fold<int>(0, (a, r) => a + r.melhorias);
    final totalMs = rows.fold<int>(0, (a, r) => a + r.elapsedMs);
    final totals = _sumBugs(rows);
    final points = rows.map((r) => ChartCyclePoint('${r.cardName} · C${r.index}', r.bugs)).toList();

    return PixelPanel(
      border: done ? Px.line : Px.purple,
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PixelBadge('SPRINT', bg: done ? Px.line2 : Px.purple, fg: done ? Px.muted : Colors.white),
              const SizedBox(width: 4),
              PixelBadge(
                done ? 'CONCLUÍDA' : 'EM ANDAMENTO',
                bg: done ? const Color(0xFF0F3D27) : const Color(0xFF0B3A4A),
                fg: done ? Px.green : Px.cyan,
                ring: done ? Px.green : Px.cyan,
              ),
              const Spacer(),
              PixelButton(
                icon: collapsed ? Icons.expand_more : Icons.expand_less,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                tooltip: collapsed ? 'Expandir sprint' : 'Recolher sprint',
                onPressed: () => app.toggleTblSprintCollapse(sprint.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(sprint.name.toUpperCase(), style: Px.p(11, color: done ? Px.muted : Px.yellow, height: 1.5)),
          Text('${matchingCards.length} card(s) · visão geral', style: Px.v(19, color: Px.muted)),
          if (!collapsed) ...[
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Text('Nenhum ciclo encontrado com os filtros atuais.', style: Px.v(20, color: Px.muted))
            else ...[
              Row(
                children: [
                  Expanded(child: _stat('CICLOS', '${rows.length}', Px.cyan)),
                  Expanded(child: _stat('TEMPO', fmtTime(totalMs), Px.yellow)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _stat('BUGS', '${totals.total}', Px.red)),
                  Expanded(child: _stat('MELHORIAS', '$totalMelhorias', Px.violet)),
                ],
              ),
              const SizedBox(height: 6),
              Text('CICLOS DA SPRINT', style: Px.p(9, color: Px.yellow, height: 1.5)),
              const SizedBox(height: 6),
              for (final r in rows) _CycleLine(row: r),
              const SizedBox(height: 10),
              _ChartBox(child: PriorityBarChart(points: points)),
              _ChartBox(child: CriticalLevelChart(points: points)),
              _ChartBox(child: TotalBugsBarChart(points: points)),
              _ChartBox(child: BugsLevelLineChart(points: points)),
            ],
            const SizedBox(height: 8),
            ...matchingCards.map((c) => _CardBlock(sprint: sprint, card: c, cycleFilter: cycleFilter)),
          ],
        ],
      ),
    );
  }
}

class _ChartBox extends StatelessWidget {
  const _ChartBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Px.panelDark, boxShadow: [BoxShadow(color: Colors.black, spreadRadius: 2)]),
      child: child,
    );
  }
}

/// Uma linha da tabela consolidada: card, ciclo, executado em, tempo e bugs.
class _CycleLine extends StatelessWidget {
  const _CycleLine({required this.row});
  final _SprintRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Px.panelDark, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('${row.cardName.toUpperCase()} · #${row.index}', style: Px.p(8, height: 1.5))),
              Text(fmtTime(row.elapsedMs), style: Px.v(23, color: Px.yellow)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('EXECUTADO EM ', style: Px.p(7, color: Px.muted, height: 1)),
              Text(fmtExecutado(row.finishedAt), style: Px.v(19)),
            ],
          ),
          const SizedBox(height: 6),
          BugBadges(bugs: row.bugs, melhorias: row.melhorias),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.sprint, required this.card, required this.cycleFilter});
  final Sprint sprint;
  final CardItem card;
  final int? cycleFilter;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final collapsed = app.tblCollapsedCards.contains(card.id);

    var cycles = card.cycles.asMap().entries.map((e) => MapEntry(e.key + 1, e.value)).toList();
    if (cycleFilter != null) {
      cycles = cycles.where((e) => e.key == cycleFilter).toList();
      if (cycles.isEmpty) return const SizedBox.shrink();
    }
    final points = cycles.map((e) => ChartCyclePoint('Ciclo ${e.key}', e.value.bugs)).toList();
    final totalMs = cycles.fold<int>(0, (a, e) => a + e.value.elapsedMs);

    return PixelPanel(
      fill: Px.panelDark,
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => app.toggleTblCardCollapse(card.id),
            child: Row(
              children: [
                Icon(collapsed ? Icons.chevron_right : Icons.expand_more, size: 20, color: Px.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CARD', style: Px.p(7, color: Px.cyan, height: 1)),
                      const SizedBox(height: 6),
                      Text(card.name.toUpperCase(), style: Px.p(8, height: 1.5)),
                    ],
                  ),
                ),
                Text(fmtTime(totalMs), style: Px.v(21, color: Px.yellow)),
              ],
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 10),
            if (cycles.isEmpty)
              Text('Nenhum ciclo finalizado ainda.', style: Px.v(20, color: Px.muted))
            else
              for (final e in cycles)
                _CycleLine(
                  row: _SprintRow(card.name, e.key, e.value.elapsedMs, e.value.bugs, e.value.melhorias, e.value.finishedAt),
                ),
            const SizedBox(height: 6),
            _ChartBox(child: PriorityBarChart(points: points)),
            _ChartBox(child: CriticalLevelChart(points: points)),
            _ChartBox(child: TotalBugsBarChart(points: points)),
            _ChartBox(child: BugsLevelLineChart(points: points)),
          ],
        ],
      ),
    );
  }
}
