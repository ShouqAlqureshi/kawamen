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

  // Helper method to convert from Dart weekday (1=Monday, 7=Sunday)
  // to display weekday (1=Sunday, 2=Monday, ..., 7=Saturday)
  int _convertWeekday(int dartWeekday) {
    // Convert from Dart weekday to display weekday
    if (dartWeekday == 7) {
      // Sunday in Dart is 7
      return 1; // Sunday should be 1 in our display
    } else {
      return dartWeekday + 1; // Monday(1) becomes 2, Tuesday(2) becomes 3, etc.
    }
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
              lineBarsData: [
                LineChartBarData(
                  //sad
                  spots: sadEmotionalData.entries.map((e) {
                    // Convert the weekday number before creating the FlSpot
                    return FlSpot(
                        _convertWeekday(e.key).toDouble(), e.value.toDouble());
                  }).toList(),
                  isCurved: true,
                  isStrokeCapRound: true,
                  color: Colors.blue,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  //anger
                  spots: angerEmotionalData.entries.map((e) {
                    // Convert the weekday number before creating the FlSpot
                    return FlSpot(
                        _convertWeekday(e.key).toDouble(), e.value.toDouble());
                  }).toList(),
                  isCurved: true,
                  isStrokeCapRound: true,
                  color: Colors.red,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
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
        text = 'SUN';
        break;
      case 2:
        text = 'MON';
        break;
      case 3:
        text = 'TUE';
        break;
      case 4:
        text = 'WED';
        break;
      case 5:
        text = 'THU';
        break;
      case 6:
        text = 'FRI';
        break;
      case 7:
        text = 'SAT';
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
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 40,
          ),
        ),
      );
}
