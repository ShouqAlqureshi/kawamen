import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmotionalTrendGraph extends StatelessWidget {
  final Map<int, int> sadEmotionalData; // map of day:count
  final Map<int, int> angerEmotionalData;

  const EmotionalTrendGraph(
      {Key? key,
      required this.angerEmotionalData,
      required this.sadEmotionalData})
      : super(key: key);

  // Create spots with explicit sorting to ensure points are in order
  List<FlSpot> _createSortedSpots(Map<int, int> data) {
    // Convert to list of entries and sort by display position
    final entries = data.entries.map((entry) {
      // Convert Dart weekday to chart position (1-7 where 1=Sunday)
      int displayDay;
      switch (entry.key) {
        case 1:
          displayDay = 2;
          break; // Monday -> 2
        case 2:
          displayDay = 3;
          break; // Tuesday -> 3
        case 3:
          displayDay = 4;
          break; // Wednesday -> 4
        case 4:
          displayDay = 5;
          break; // Thursday -> 5
        case 5:
          displayDay = 6;
          break; // Friday -> 6
        case 6:
          displayDay = 7;
          break; // Saturday -> 7
        case 7:
          displayDay = 1;
          break; // Sunday -> 1
        default:
          displayDay = 1;
      }
      return MapEntry(displayDay, entry.value);
    }).toList();

    // Sort by display day to ensure correct order
    entries.sort((a, b) => a.key.compareTo(b.key));

    // Convert to FlSpot list
    return entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend (indicator)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sad indicator
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'حزين',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Anger indicator
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'غاضب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The chart
        Expanded(
            child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: titlesData,
            borderData: FlBorderData(show: false),
            minX: 1,
            maxX: 7,
            minY: 0,
            maxY: _getMaxY().toDouble(),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (LineBarSpot touchedSpot) => Colors.black,
              ),
              handleBuiltInTouches: true,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _createSortedSpots(sadEmotionalData),
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                isStrokeCapRound: true,
                color: Colors.blue.withOpacity(0.6),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.transparent,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              LineChartBarData(
                spots: _createSortedSpots(angerEmotionalData),
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                isStrokeCapRound: true,
                color: Colors.red.withOpacity(0.6),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.red,
                      strokeWidth: 2,
                      strokeColor: Colors.transparent,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget getTitles(double value, TitleMeta? meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Colors.white,
    );

    String text;
    switch (value.toInt()) {
      case 1:
        text = 'الأحد';
        break;
      case 2:
        text = 'الاثنين';
        break;
      case 3:
        text = 'الثلاثاء';
        break;
      case 4:
        text = 'الاربعاء';
        break;
      case 5:
        text = 'الخميس';
        break;
      case 6:
        text = 'الجمعة';
        break;
      case 7:
        text = 'السبت';
        break;
      default:
        text = '';
        break;
    }

    return Text(
      text,
      style: style,
    );
  }

  int _getMaxY() {
    final allValues = [
      ...sadEmotionalData.values,
      ...angerEmotionalData.values
    ];
    if (allValues.isEmpty) return 5;

    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    // Round up to the nearest multiple of interval (5, 10, etc.)
    final interval = _getYInterval(maxVal);
    return ((maxVal / interval).ceil()) * interval;
  }

  int _getYInterval(int maxVal) {
    if (maxVal <= 5) return 1;
    if (maxVal <= 10) return 2;
    if (maxVal <= 20) return 5;
    if (maxVal <= 50) return 10;
    if (maxVal <= 100) return 20;
    return 50;
  }

  FlTitlesData get titlesData => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: getTitles,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getYInterval(_getMaxY()).toDouble(),
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}
