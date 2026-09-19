import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/pixel.dart';
import 'bug_badges.dart';

class FinishCycleResult {
  final Bugs bugs;
  final int melhorias;
  FinishCycleResult(this.bugs, this.melhorias);
}

/// Janela "Finalizar ciclo": quantidade de bugs por prioridade e melhorias.
Future<FinishCycleResult?> showFinishCycleDialog(
  BuildContext context, {
  required int cycleNumber,
  required int elapsedMs,
}) {
  return showPixelDialog<FinishCycleResult>(
    context,
    dismissible: false,
    builder: (ctx) => _FinishCycleBody(cycleNumber: cycleNumber, elapsedMs: elapsedMs),
  );
}

class _FinishCycleBody extends StatefulWidget {
  const _FinishCycleBody({required this.cycleNumber, required this.elapsedMs});
  final int cycleNumber;
  final int elapsedMs;

  @override
  State<_FinishCycleBody> createState() => _FinishCycleBodyState();
}

class _FinishCycleBodyState extends State<_FinishCycleBody> {
  int critico = 0, bloqueado = 0, medio = 0, baixo = 0, melhorias = 0;

  Widget _row(String label, String desc, Color color, int value, ValueChanged<int> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: const BoxDecoration(color: Px.panelDark, boxShadow: [BoxShadow(color: Px.line2, spreadRadius: 2)]),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Px.p(9, height: 1)),
                const SizedBox(height: 6),
                Text(desc, style: Px.v(16, color: const Color(0xFF8FA0D0))),
              ],
            ),
          ),
          PixelButton(
            icon: Icons.remove,
            iconSize: 14,
            width: 38,
            height: 34,
            padding: EdgeInsets.zero,
            tooltip: 'Diminuir $label',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(width: 26, child: Text('$value', textAlign: TextAlign.center, style: Px.p(11, color: color, height: 1))),
          PixelButton(
            icon: Icons.add,
            iconSize: 14,
            width: 38,
            height: 34,
            padding: EdgeInsets.zero,
            tooltip: 'Aumentar $label',
            onPressed: value < 99 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FINALIZAR CICLO #${widget.cycleNumber}', style: Px.p(11, color: Px.cyan, height: 1.6)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'TEMPO REGISTRADO: ', style: Px.p(8, color: Px.muted, height: 1.7)),
            TextSpan(text: fmtTime(widget.elapsedMs), style: Px.p(8, color: Px.green, height: 1.7)),
          ])),
          const SizedBox(height: 10),
          Text('BUGS POR PRIORIDADE', style: Px.p(8, color: Px.amber)),
          const SizedBox(height: 4),
          _row('Crítico', 'IMPEDE O FLUXO PRINCIPAL', Px.critico, critico, (v) => setState(() => critico = v)),
          _row('Bloqueado', 'IMPEDE TESTES OU RELEASE', Px.bloqueado, bloqueado, (v) => setState(() => bloqueado = v)),
          _row('Médio', 'EXISTE FLUXO ALTERNATIVO', Px.medio, medio, (v) => setState(() => medio = v)),
          _row('Baixo', 'TEXTO OU ALINHAMENTO', Px.baixo, baixo, (v) => setState(() => baixo = v)),
          const SizedBox(height: 8),
          Text('MELHORIAS', style: Px.p(8, color: Px.violet)),
          const SizedBox(height: 4),
          _row('Melhorias', 'SUGESTÕES, NÃO SÃO BUGS', Px.melhoria, melhorias, (v) => setState(() => melhorias = v)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: PixelButton(label: 'DESCARTAR', fontSize: 8, onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'CONCLUIR',
                  variant: PxVariant.green,
                  fontSize: 8,
                  onPressed: () => Navigator.pop(
                    context,
                    FinishCycleResult(
                      Bugs(critico: critico, bloqueado: bloqueado, medio: medio, baixo: baixo),
                      melhorias,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
