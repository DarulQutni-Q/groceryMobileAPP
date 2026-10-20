import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grocery_shared/shared.dart';

import '../../store/presentation/store_widgets.dart';

class LaporanChart extends StatefulWidget {
  const LaporanChart({super.key, required this.days});
  final List<PenjualanHarian> days;
  @override
  State<LaporanChart> createState() => _LaporanChartState();
}

class _LaporanChartState extends State<LaporanChart> {
  int? _selected;
  String _label(int index) {
    final day = widget.days[index].tanggal;
    return widget.days.length == 7
        ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day.weekday -
              1]
        : day.day.toString();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final maxValue = days.fold<double>(
      0,
      (value, day) => math.max(value, day.total.toDouble()),
    );
    final selected = _selected != null && _selected! < days.length
        ? days[_selected!]
        : null;
    return Semantics(
      label: 'Penjualan per hari',
      value: selected == null
          ? 'Ketuk batang untuk melihat nominal.'
          : '${MaterialLocalizations.of(context).formatMediumDate(selected.tanggal)}, ${rupiah(selected.total)}',
      child: SizedBox(
        height: 235,
        child: LayoutBuilder(
          builder: (context, size) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(size.maxWidth, days.length * 32.0),
              child: BarChart(
                BarChartData(
                  maxY: maxValue == 0 ? 1 : maxValue * 1.15,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFCDD4C7), strokeWidth: .5),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _label(index),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                      final index = response?.spot?.touchedBarGroupIndex;
                      if (event is FlTapUpEvent && mounted) {
                        setState(() => _selected = index);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => const Color(0xFF3B6341),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${MaterialLocalizations.of(context).formatMediumDate(days[groupIndex].tanggal)}\n${rupiah(days[groupIndex].total)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        showingTooltipIndicators: _selected == i ? [0] : [],
                        barRods: [
                          BarChartRodData(
                            toY: days[i].total.toDouble(),
                            width: 17,
                            color: i == days.length - 1
                                ? const Color(0xFF3B6341)
                                : const Color(0xFF83AC9E),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
