import 'package:flutter/material.dart';

import '../models/app_models.dart';

class FinishCycleResult {
  final Bugs bugs;
  final int melhorias;
  FinishCycleResult(this.bugs, this.melhorias);
}

Future<FinishCycleResult?> showFinishCycleDialog(BuildContext context) {
  final critico = TextEditingController(text: '0');
  final bloqueado = TextEditingController(text: '0');
  final medio = TextEditingController(text: '0');
  final baixo = TextEditingController(text: '0');
  final melhorias = TextEditingController(text: '0');

  Widget field(String label, Color color, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            ),
          ),
        ],
      ),
    );
  }

  return showDialog<FinishCycleResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Finalizar Ciclo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bugs por prioridade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            field('Crítico', Colors.redAccent, critico),
            field('Bloqueado', Colors.orangeAccent, bloqueado),
            field('Médio', Colors.amber, medio),
            field('Baixo', Colors.greenAccent, baixo),
            const Divider(height: 24),
            field('Melhorias encontradas', Colors.blueAccent, melhorias),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final bugs = Bugs(
              critico: int.tryParse(critico.text) ?? 0,
              bloqueado: int.tryParse(bloqueado.text) ?? 0,
              medio: int.tryParse(medio.text) ?? 0,
              baixo: int.tryParse(baixo.text) ?? 0,
            );
            final m = int.tryParse(melhorias.text) ?? 0;
            Navigator.pop(ctx, FinishCycleResult(bugs, m));
          },
          child: const Text('Salvar Ciclo'),
        ),
      ],
    ),
  );
}
