import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../theme/pixel.dart';

String fmtTime(int ms) {
  final totalSec = ms ~/ 1000;
  final h = (totalSec ~/ 3600).toString().padLeft(2, '0');
  final m = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (totalSec % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// "Hoje, 09:30", "Ontem, 16:40" ou "22/05, 14:02" (usa o campo finishedAt do ciclo).
String fmtExecutado(int epochMs, {DateTime? now}) {
  final when = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(when.year, when.month, when.day);
  final diff = today.difference(day).inDays;
  final hour = DateFormat('HH:mm').format(when);
  if (diff == 0) return 'Hoje, $hour';
  if (diff == 1) return 'Ontem, $hour';
  return '${DateFormat('dd/MM').format(when)}, $hour';
}

class BugBadges extends StatelessWidget {
  const BugBadges({super.key, required this.bugs, this.melhorias, this.showTotal = false, this.showZero = true});

  final Bugs bugs;
  final int? melhorias;
  final bool showTotal;
  final bool showZero;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (bugs.critico > 0) PixelBadge('CRÍTICO ${bugs.critico}', bg: Px.critico, fg: Colors.black),
      if (bugs.bloqueado > 0) PixelBadge('BLOQUEADO ${bugs.bloqueado}', bg: Px.bloqueado, fg: Colors.black),
      if (bugs.medio > 0) PixelBadge('MÉDIO ${bugs.medio}', bg: Px.medio, fg: Colors.black),
      if (bugs.baixo > 0) PixelBadge('BAIXO ${bugs.baixo}', bg: Px.baixo, fg: Colors.black),
      if ((melhorias ?? 0) > 0) PixelBadge('MELHORIAS $melhorias', bg: Px.melhoria, fg: Colors.white),
      if (bugs.total == 0 && (melhorias ?? 0) == 0 && showZero) const PixelBadge('SEM BUGS', bg: Px.green, fg: Colors.black),
    ];
    if (showTotal) {
      badges.add(Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: Text('total ${bugs.total}', style: Px.v(18, color: Px.muted)),
      ));
    }
    return Wrap(spacing: 4, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: badges);
  }
}
