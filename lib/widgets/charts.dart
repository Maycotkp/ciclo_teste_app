import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/pixel.dart';

class ChartCyclePoint {
  final String label;
  final Bugs bugs;
  ChartCyclePoint(this.label, this.bugs);
}

Widget _chartTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontFamily: 'PressStart', fontSize: 8, height: 1.5, color: Px.text)),
    );

class PriorityBarChart extends StatelessWidget {
  const PriorityBarChart({super.key, required this.points});
  final List<ChartCyclePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('Sem dados ainda', style: TextStyle(fontFamily: 'VT323', fontSize: 20, color: Px.muted))));
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
                  BarChartRodData(toY: b.critico.toDouble(), color: Px.critico, width: 6),
                  BarChartRodData(toY: b.bloqueado.toDouble(), color: Px.bloqueado, width: 6),
                  BarChartRodData(toY: b.medio.toDouble(), color: Px.green, width: 6),
                  BarChartRodData(toY: b.baixo.toDouble(), color: Px.baixo, width: 6),
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
                        child: Text(points[idx].label, style: const TextStyle(fontFamily: 'VT323', fontSize: 15, color: Px.muted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Px.line2, strokeWidth: 1)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, children: const [
          _LegendDot(color: Px.critico, label: 'Crítico'),
          _LegendDot(color: Px.bloqueado, label: 'Bloqueado'),
          _LegendDot(color: Px.green, label: 'Médio'),
          _LegendDot(color: Px.baixo, label: 'Baixo'),
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
      return const SizedBox(height: 120, child: Center(child: Text('Sem dados ainda', style: TextStyle(fontFamily: 'VT323', fontSize: 20, color: Px.muted))));
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
                  isCurved: false,
                  color: const Color(0xFFFB7185),
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
                        child: Text(points[idx].label, style: const TextStyle(fontFamily: 'VT323', fontSize: 15, color: Px.muted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Px.line2, strokeWidth: 1)),
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
      return const SizedBox(height: 160, child: Center(child: Text('Sem dados ainda', style: TextStyle(fontFamily: 'VT323', fontSize: 20, color: Px.muted))));
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
                  BarChartRodData(toY: e.value.toDouble(), color: Px.cyan, width: 14, borderRadius: BorderRadius.zero),
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
                        child: Text(points[idx].label, style: const TextStyle(fontFamily: 'VT323', fontSize: 15, color: Px.muted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Px.line2, strokeWidth: 1)),
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
      return const SizedBox(height: 120, child: Center(child: Text('Sem dados ainda', style: TextStyle(fontFamily: 'VT323', fontSize: 20, color: Px.muted))));
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
                  isCurved: false,
                  color: Px.green,
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
                        child: Text(points[idx].label, style: const TextStyle(fontFamily: 'VT323', fontSize: 15, color: Px.muted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Px.line2, strokeWidth: 1)),
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
      Container(width: 10, height: 10, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontFamily: 'VT323', fontSize: 16, color: Px.muted)),
    ]);
  }
}
