import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/time_models.dart';
import '../state/time_provider.dart';
import '../theme/pixel.dart';
import '../widgets/bug_badges.dart';

const _monthNames = [
  'JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO',
  'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO',
];

class AtividadesTab extends StatefulWidget {
  const AtividadesTab({super.key});

  @override
  State<AtividadesTab> createState() => _AtividadesTabState();
}

class _AtividadesTabState extends State<AtividadesTab> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _createProject(BuildContext context, TimeProvider time) async {
    final name = await pixelPrompt(context, title: 'NOVO PROJETO', hint: 'NOME DO PROJETO');
    if (name != null) time.addProject(name);
  }

  void _start(TimeProvider time) {
    time.startNew(_nameController.text, category: _categoryController.text);
    _nameController.clear();
    _categoryController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final time = context.watch<TimeProvider>();
    final editable = time.isEditable;
    final acts = time.visibleActivities;
    final formProject = time.projectById(time.filterProjectId)?.name.toUpperCase() ?? 'SEM PROJETO';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        // ---- Projetos (opcional) ----
        PixelPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROJETOS (OPCIONAL)', style: Px.p(8, color: Px.violet, height: 1)),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  PixelChip('TODOS', selected: time.filterProjectId == null, onTap: () => time.setFilter(null)),
                  for (final p in time.state.projects)
                    PixelChip(p.name.toUpperCase(), selected: time.filterProjectId == p.id, onTap: () => time.setFilter(p.id)),
                  PixelChip('+ PROJETO', onTap: () => _createProject(context, time)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ---- Atividade em foco ----
        _HeroPanel(time: time),
        const SizedBox(height: 10),

        // ---- Calendário ----
        _CalendarPanel(
          time: time,
          month: _month,
          onMonth: (m) => setState(() => _month = m),
        ),
        const SizedBox(height: 10),

        if (!editable)
          PixelPanel(
            border: Px.amber,
            padding: const EdgeInsets.all(12),
            child: Text(
              time.isToday
                  ? 'DIA ENCERRADO (TRAVA AUTOMÁTICA ÀS 23:55). SOMENTE LEITURA.'
                  : 'DIA ENCERRADO · SOMENTE LEITURA. TOQUE EM HOJE PARA CRONOMETRAR.',
              style: Px.p(8, color: Px.amber, height: 1.7),
            ),
          )
        else
          PixelPanel(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('NOVA ATIVIDADE', style: Px.p(8, color: Px.violet, height: 1)),
                const SizedBox(height: 6),
                PixelTextField(controller: _nameController, hint: 'NOME DA ATIVIDADE'),
                PixelTextField(controller: _categoryController, hint: 'CATEGORIA (OPCIONAL)'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: 'PROJETO: ', style: Px.p(7, color: Px.muted, height: 1.6)),
                    TextSpan(text: formProject, style: Px.p(7, color: Px.cyan, height: 1.6)),
                    TextSpan(text: ' · ESCOLHA NO TOPO', style: Px.p(7, color: Px.muted, height: 1.6)),
                  ])),
                ),
                PixelButton(label: 'INICIAR', variant: PxVariant.purple, height: 48, onPressed: () => _start(time)),
              ],
            ),
          ),
        const SizedBox(height: 14),

        Text('ATIVIDADES (${acts.length})', style: Px.p(9, color: Px.yellow, height: 1.5)),
        const SizedBox(height: 6),
        if (acts.isEmpty)
          PixelPanel(
            border: Px.amber,
            padding: const EdgeInsets.all(12),
            child: Text(
              time.filterProjectId == null ? 'NENHUMA ATIVIDADE NESTE DIA.' : 'NENHUMA ATIVIDADE NESTE PROJETO AINDA.',
              style: Px.p(8, color: Px.amber, height: 1.7),
            ),
          )
        else
          for (final a in acts) _ActivityCard(key: ValueKey(a.id), activity: a),
      ],
    );
  }
}

// ====================== Atividade em foco (cronômetro grande) ======================

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.time});
  final TimeProvider time;

  @override
  Widget build(BuildContext context) {
    final hero = time.heroActivity;
    final running = hero?.running ?? false;
    final editable = time.isEditable;
    final color = running ? Px.green : Px.amber;
    final project = time.projectById(hero?.projectId);

    return PixelPanel(
      border: Px.cyan,
      fill: Px.panelDark,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ATIVIDADE EM FOCO', style: Px.p(8, color: Px.cyan, height: 1)),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(hero?.name ?? 'Nenhuma atividade', style: Px.p(9, height: 1.7)),
              ),
              if (hero != null && hero.category.isNotEmpty) PixelBadge(hero.category, bg: Px.line2, fg: const Color(0xFF7DD3FC)),
              if (project != null) PixelBadge(project.name.toUpperCase(), bg: const Color(0xFF2A1650), fg: Px.violet),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, color: color),
                    const SizedBox(width: 7),
                    Text(running ? 'RODANDO' : 'PAUSADA', style: Px.p(8, color: color, height: 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    fmtTime(hero?.elapsedMs() ?? 0),
                    style: Px.v(78, color: color).copyWith(letterSpacing: 2, shadows: [Shadow(color: color, blurRadius: 10)]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  icon: Icons.play_arrow,
                  iconSize: 36,
                  height: 72,
                  variant: PxVariant.green,
                  tooltip: 'Play',
                  onPressed: (editable && hero != null && !running) ? time.heroPlay : null,
                ),
              ),
              Expanded(
                child: PixelButton(
                  icon: Icons.pause,
                  iconSize: 36,
                  height: 72,
                  variant: PxVariant.purple,
                  tooltip: 'Pausar',
                  onPressed: (editable && running) ? time.heroPause : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================== Calendário ======================

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({required this.time, required this.month, required this.onMonth});

  final TimeProvider time;
  final DateTime month;
  final ValueChanged<DateTime> onMonth;

  static const _dow = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7; // domingo = 0
    final cells = ((lead + daysInMonth + 6) ~/ 7) * 7;
    final records = time.daysWithRecords;
    final todayKey = time.todayKey;
    final selectedKey = time.selectedKey;

    final selected = time.selectedDate;
    final dayLabel = '${selected.day} DE ${_monthNames[selected.month - 1]}';

    return PixelPanel(
      border: Px.cyan,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${_monthNames[month.month - 1]} ${month.year}', style: Px.p(10, color: Px.yellow, height: 1.4))),
              PixelButton(
                icon: Icons.chevron_left,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                tooltip: 'Mês anterior',
                onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
              ),
              PixelButton(
                icon: Icons.chevron_right,
                width: 34,
                height: 34,
                padding: EdgeInsets.zero,
                tooltip: 'Próximo mês',
                onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
              ),
              PixelButton(
                label: 'HOJE',
                variant: PxVariant.green,
                fontSize: 8,
                height: 34,
                onPressed: () {
                  time.goToday();
                  final t = DateTime.now();
                  onMonth(DateTime(t.year, t.month));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in _dow)
                Expanded(child: Center(child: Text(d, style: Px.p(7, color: Px.muted, height: 1)))),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < cells ~/ 7; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _dayCell(
                        first.add(Duration(days: row * 7 + col - lead)),
                        inMonth: (row * 7 + col - lead) >= 0 && (row * 7 + col - lead) < daysInMonth,
                        records: records,
                        todayKey: todayKey,
                        selectedKey: selectedKey,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend(Px.amber, 'HOJE', ring: true),
              _legend(Px.purple, 'DIA ABERTO'),
              _legend(Px.green, 'COM REGISTRO', small: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayLabel, style: Px.p(9, height: 1.2)),
                    const SizedBox(height: 7),
                    Text(time.isToday ? 'hoje' : 'somente leitura', style: Px.v(19, color: Px.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(color: Colors.black, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TOTAL DO DIA', style: Px.p(7, color: Px.muted, height: 1)),
                    const SizedBox(height: 6),
                    Text(fmtTime(time.visibleTotalMs), style: Px.v(30, color: Px.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label, {bool ring = false, bool small = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: small ? 4 : 10,
          height: small ? 4 : 10,
          decoration: BoxDecoration(
            color: ring ? const Color(0xFF2A1F05) : c,
            boxShadow: ring ? [BoxShadow(color: c, spreadRadius: 2)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Px.p(7, color: c, height: 1)),
      ],
    );
  }

  Widget _dayCell(
    DateTime d, {
    required bool inMonth,
    required Set<String> records,
    required String todayKey,
    required String selectedKey,
  }) {
    final key = dateKeyOf(d);
    final isToday = key == todayKey;
    final isSelected = key == selectedKey;
    final hasRecord = records.contains(key);

    Color fill = Px.panelDark;
    Color text = const Color(0xFFE6EAFF);
    final shadows = <BoxShadow>[const BoxShadow(color: Px.line2, spreadRadius: 2)];
    if (!inMonth) {
      text = const Color(0xFF5A6690);
      shadows
        ..clear()
        ..add(const BoxShadow(color: Px.panel, spreadRadius: 2));
    }
    if (isToday) {
      fill = const Color(0xFF2A1F05);
      text = Px.amber;
      shadows
        ..clear()
        ..add(const BoxShadow(color: Px.amber, spreadRadius: 2));
    }
    if (isSelected) {
      fill = Px.purple;
      text = Colors.white;
      shadows.clear();
      // A sombra maior vem primeiro, para o anel âmbar do "hoje" ficar por cima dela.
      if (isToday) shadows.add(const BoxShadow(color: Colors.black, spreadRadius: 4));
      shadows.add(BoxShadow(color: isToday ? Px.amber : Px.cyan, spreadRadius: 2));
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: isToday ? 'Hoje, dia ${d.day}' : 'Dia ${d.day} de ${_monthNames[d.month - 1].toLowerCase()}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => time.selectDate(d),
          child: Container(
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: fill, boxShadow: shadows),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.day.toString().padLeft(2, '0'), style: Px.p(9, color: text, height: 1)),
                const SizedBox(height: 4),
                Container(width: 4, height: 4, color: hasRecord && inMonth ? (isSelected ? Colors.white : Px.green) : Colors.transparent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================== Cartão de atividade (com checklist) ======================

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({super.key, required this.activity});
  final WorkActivity activity;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _addItem(TimeProvider time) {
    time.addItem(widget.activity.id, _draft.text);
    _draft.clear();
  }

  @override
  Widget build(BuildContext context) {
    final time = context.watch<TimeProvider>();
    final a = widget.activity;
    final editable = time.isEditable;
    final running = a.running;
    final project = time.projectById(a.projectId);
    final total = a.items.length;

    return PixelPanel(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PixelBadge(
                running ? 'RODANDO' : 'PAUSADA',
                bg: running ? const Color(0xFF0F3D27) : const Color(0xFF3D2E06),
                fg: running ? Px.green : Px.amber,
                ring: running ? Px.green : Px.amber,
              ),
              if (a.category.isNotEmpty) PixelBadge(a.category, bg: Px.line2, fg: const Color(0xFF7DD3FC)),
              if (project != null) PixelBadge(project.name.toUpperCase(), bg: const Color(0xFF2A1650), fg: Px.violet),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.name, style: Px.p(9, height: 1.7)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(fmtTime(a.elapsedMs()), style: Px.v(38, color: running ? Px.green : Px.yellow))),
              PixelButton(
                icon: running ? Icons.pause : Icons.play_arrow,
                iconSize: 22,
                width: 52,
                variant: running ? PxVariant.purple : PxVariant.cyan,
                tooltip: running ? 'Pausar' : 'Retomar',
                onPressed: editable ? () => time.toggle(a.id) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (total > 0) ...[
                Expanded(child: PixelProgressBar(value: a.progress, color: a.progress >= 1 ? Px.green : Px.cyan)),
                const SizedBox(width: 10),
                Text('${a.doneCount}/$total', style: Px.v(22)),
              ] else
                Expanded(child: Text('Sem checklist', style: Px.v(20, color: Px.dim))),
              PixelButton(
                icon: a.expanded ? Icons.expand_less : Icons.expand_more,
                iconSize: 18,
                width: 44,
                height: 36,
                padding: EdgeInsets.zero,
                tooltip: a.expanded ? 'Recolher checklist' : 'Expandir checklist',
                onPressed: () => time.toggleExpanded(a.id),
              ),
            ],
          ),
          if (a.expanded) ...[
            const Divider(color: Px.line2, thickness: 2, height: 20),
            Text('CHECKLIST (OPCIONAL)', style: Px.p(8, color: Px.violet, height: 1)),
            const SizedBox(height: 6),
            if (total == 0)
              Text(
                editable ? 'Nenhum item ainda. Adicione o primeiro abaixo para criar a checklist.' : 'Esta atividade não tem checklist.',
                style: Px.v(20, color: Px.muted, height: 1.1),
              ),
            for (final item in a.items)
              Row(
                children: [
                  PixelCheckbox(
                    value: item.done,
                    label: (item.done ? 'Desmarcar: ' : 'Marcar: ') + item.text,
                    onChanged: editable ? (_) => time.toggleItem(a.id, item.id) : null,
                  ),
                  Expanded(
                    child: Text(
                      item.text,
                      style: Px.v(22, color: item.done ? Px.dim : Px.text, height: 1.05).copyWith(
                        decoration: item.done ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: Px.dim,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            if (editable)
              Row(
                children: [
                  Expanded(child: PixelTextField(controller: _draft, hint: 'NOVO ITEM', onSubmitted: (_) => _addItem(time))),
                  PixelButton(
                    icon: Icons.add,
                    width: 48,
                    variant: PxVariant.cyan,
                    tooltip: 'Adicionar item',
                    onPressed: () => _addItem(time),
                  ),
                ],
              )
            else
              PixelPanel(
                border: Px.amber,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(4),
                child: Text(
                  'DIA ENCERRADO · CHECKLIST SOMENTE LEITURA. NÃO DÁ PARA ADICIONAR NEM MARCAR ITENS.',
                  style: Px.p(7, color: Px.amber, height: 1.8),
                ),
              ),
            const SizedBox(height: 8),
            Text('PROJETO DA ATIVIDADE (OPCIONAL)', style: Px.p(8, color: Px.violet, height: 1)),
            const SizedBox(height: 6),
            Wrap(
              children: [
                PixelChip('SEM PROJETO', selected: a.projectId == null, onTap: editable ? () => time.setActivityProject(a.id, null) : null),
                for (final p in time.state.projects)
                  PixelChip(
                    p.name.toUpperCase(),
                    selected: a.projectId == p.id,
                    onTap: editable ? () => time.setActivityProject(a.id, p.id) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
