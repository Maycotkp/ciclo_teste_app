import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/app_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final project = app.currentProject;
    final term = app.tblSearch.trim().toLowerCase();

    final cardOptions = <MapEntry<String, String>>[]; // id -> label
    for (final s in project.sprints) {
      if (app.tblSprintId != null && s.id != app.tblSprintId) continue;
      for (final c in s.cards) {
        cardOptions.add(MapEntry(c.id, app.tblSprintId != null ? c.name : '${s.name} / ${c.name}'));
      }
    }
    if (app.tblCardId != null && !cardOptions.any((e) => e.key == app.tblCardId)) {
      app.tblCardId = null;
    }

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por sprint ou card...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: app.setTblSearch,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: app.tblSprintId,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), labelText: 'Sprint'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas as Sprints')),
                        ...project.sprints.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: app.setTblSprintId,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: app.tblCardId,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), labelText: 'Card'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos os Cards')),
                        ...cardOptions.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: app.setTblCardId,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _cycleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), labelText: 'Nº do ciclo'),
                      onChanged: (v) => app.setTblCycle(int.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => _clearFilters(app), child: const Text('Limpar filtros')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('Nenhum resultado para os filtros selecionados.', style: TextStyle(color: Colors.grey)))
              : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: groups),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final collapsed = app.tblCollapsedSprints.contains(sprint.id);
    final totalMelhorias = rows.fold<int>(0, (a, r) => a + r.melhorias);
    final totalMs = rows.fold<int>(0, (a, r) => a + r.elapsedMs);
    final totals = _sumBugs(rows);
    final points = rows.map((r) => ChartCyclePoint('${r.cardName} · C${r.index}', r.bugs)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => app.toggleTblSprintCollapse(sprint.id),
              child: Row(
                children: [
                  Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                    child: const Text('SPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sprint.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Text('${matchingCards.length} card(s) · visão geral', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            if (!collapsed) ...[
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Text('Nenhum ciclo encontrado com os filtros atuais.', style: TextStyle(color: Colors.grey))
              else ...[
                _SummaryTable(rows: rows),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      const Expanded(flex: 2, child: Text('Total da Sprint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text(fmtTime(totalMs), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 4, child: BugBadges(bugs: totals)),
                      Expanded(flex: 1, child: Text('$totalMelhorias', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PriorityBarChart(points: points),
                const SizedBox(height: 12),
                CriticalLevelChart(points: points),
                const SizedBox(height: 16),
                TotalBugsBarChart(points: points),
                const SizedBox(height: 12),
                BugsLevelLineChart(points: points),
              ],
              const SizedBox(height: 16),
              ...matchingCards.map((c) => _CardBlock(sprint: sprint, card: c, cycleFilter: cycleFilter)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.rows});
  final List<_SprintRow> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(3), 4: FlexColumnWidth(1)},
      border: TableBorder(horizontalInside: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Card', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Ciclo', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Tempo', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Bugs', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Melh.', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        for (final r in rows)
          TableRow(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(r.cardName, style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('C${r.index}', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(fmtTime(r.elapsedMs), style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: BugBadges(bugs: r.bugs, showTotal: false)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${r.melhorias}', style: const TextStyle(fontSize: 12))),
          ]),
      ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF161D2E), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2A3452))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => app.toggleTblCardCollapse(card.id),
            child: Row(
              children: [
                Icon(collapsed ? Icons.chevron_right : Icons.expand_more, size: 18),
                const SizedBox(width: 6),
                Text(sprint.name, style: const TextStyle(color: Color(0xFF5B8CFF), fontWeight: FontWeight.bold, fontSize: 12)),
                const Text(' › ', style: TextStyle(color: Colors.grey)),
                Expanded(child: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 10),
            if (cycles.isEmpty)
              const Text('Nenhum ciclo finalizado ainda.', style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              Column(
                children: cycles.map((e) {
                  final c = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 50, child: Text('C${e.key}', style: const TextStyle(fontSize: 11))),
                        SizedBox(width: 58, child: Text(fmtTime(c.elapsedMs), style: const TextStyle(fontSize: 11))),
                        Expanded(child: BugBadges(bugs: c.bugs)),
                        Text('${c.melhorias}m', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            PriorityBarChart(points: points),
            const SizedBox(height: 12),
            CriticalLevelChart(points: points),
            const SizedBox(height: 12),
            TotalBugsBarChart(points: points),
            const SizedBox(height: 12),
            BugsLevelLineChart(points: points),
          ],
        ],
      ),
    );
  }
}
