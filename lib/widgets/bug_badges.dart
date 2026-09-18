import 'package:flutter/material.dart';

import '../models/app_models.dart';

String fmtTime(int ms) {
  final totalSec = ms ~/ 1000;
  final h = (totalSec ~/ 3600).toString().padLeft(2, '0');
  final m = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (totalSec % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class BugBadges extends StatelessWidget {
  const BugBadges({super.key, required this.bugs, this.showTotal = true});
  final Bugs bugs;
  final bool showTotal;

  Widget _badge(String label, int value, Color color) {
    if (value == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 4, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label $value', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _badge('Crít', bugs.critico, Colors.redAccent),
        _badge('Bloq', bugs.bloqueado, Colors.orangeAccent),
        _badge('Méd', bugs.medio, Colors.amber),
        _badge('Baixo', bugs.baixo, Colors.greenAccent),
        if (bugs.total == 0) const Text('0', style: TextStyle(color: Colors.grey)),
        if (showTotal)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('(total ${bugs.total})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
      ],
    );
  }
}
