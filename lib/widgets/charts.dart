import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ChartCyclePoint {
  final String label;
  final Bugs bugs;
  ChartCyclePoint(this.label, this.bugs);
}

Widget _chartTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: .5)),
    );

class PriorityBarChart extends StatelessWidget {
  const PriorityBarChart({super.key, required this.points});
  final List<ChartCyclePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('Sem dados ainda', style: TextStyle(color: Colors.grey))));
    }
    double maxY = 1;
    for (final p in points) {
      for (final v in [p.bugs.critico, p.bugs.bloqueado, p.bugs.medio, p.bugs.baixo]) {
        if (v.toDouble() > maxY) maxY = v.toDouble();
      }
    }
    maxY = maxY * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartTitle('Bugs por Prioridade'),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: points.asMap().entries.map((e) {
                final i = e.key;
                final b = e.value.bugs;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: b.critico.toDouble(), color: Colors.redAccent, width: 6),
                  BarChartRodData(toY: b.bloqueado.toDouble(), color: Colors.orangeAccent, width: 6),
                  BarChartRodData(toY: b.medio.toDouble(), color: Colors.amber, width: 6),
                  BarChartRodData(toY: b.baixo.toDouble(), color: Colors.greenAccent, width: 6),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(points[idx].label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, children: const [
          _LegendDot(color: Colors.redAccent, label: 'Crítico'),
          _LegendDot(color: Colors.orangeAccent, label: 'Bloqueado'),
          _LegendDot(color: Colors.amber, label: 'Médio'),
          _LegendDot(color: Colors.greenAccent, label: 'Baixo'),
        ]),
      ],
    );
  }
}

class CriticalLevelChart extends StatelessWidget {
  const CriticalLevelChart({super.key, required this.points});
  final List<ChartCyclePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('Sem dados ainda', style: TextStyle(color: Colors.grey))));
    }
    int cum = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      cum += points[i].bugs.critico;
      spots.add(FlSpot(i.toDouble(), cum.toDouble()));
    }
    final maxY = (cum == 0 ? 1 : cum).toDouble() * 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartTitle('Nível de Críticos Abertos (acumulado)'),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF5B8CFF),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(points[idx].label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }
}

class TotalBugsBarChart extends StatelessWidget {
  const TotalBugsBarChart({super.key, required this.points});
  final List<ChartCyclePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('Sem dados ainda', style: TextStyle(color: Colors.grey))));
    }
    final totals = points.map((p) => p.bugs.total).toList();
    final maxY = (totals.isEmpty ? 1 : totals.reduce((a, b) => a > b ? a : b)).toDouble() * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartTitle('Total de Bugs por Ciclo'),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 1 : maxY,
              barGroups: totals.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: e.value.toDouble(), color: const Color(0xFF7C5BFF), width: 14, borderRadius: BorderRadius.circular(4)),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(points[idx].label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }
}

class BugsLevelLineChart extends StatelessWidget {
  const BugsLevelLineChart({super.key, required this.points});
  final List<ChartCyclePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('Sem dados ainda', style: TextStyle(color: Colors.grey))));
    }
    final spots = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bugs.total.toDouble())).toList();
    final maxVal = points.map((p) => p.bugs.total).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal == 0 ? 1 : maxVal).toDouble() * 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartTitle('Nível de Bugs por Ciclo'),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.amber,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(points[idx].label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}
