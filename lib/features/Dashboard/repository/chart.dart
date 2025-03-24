import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmotionalTrendGraph extends StatelessWidget {
  final Map<int,int>
      sadEmotionalData; // map of day :count
final Map<int,int>
      angerEmotionalData;
  const EmotionalTrendGraph({super.key, required this.angerEmotionalData,required this.sadEmotionalData});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: titlesData,
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(//sad
            spots: sadEmotionalData.entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.toDouble());
            }).toList(),
            isCurved: true,
            isStrokeCapRound: true,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
          ),
           LineChartBarData(//anger 
            spots: angerEmotionalData.entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.toDouble());
            }).toList(),
            isCurved: true,
            isStrokeCapRound: true,
            color: Colors.red,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('SUN', style: style);
        break;
      case 2:
        text = const Text('MON', style: style);
        break;
      case 3:
        text = const Text('TUE', style: style);
        break;
      case 4:
        text = const Text('WEN', style: style);
        break;
      case 5:
        text = const Text('THU', style: style);
        break;
      case 6:
        text = const Text('FRI', style: style);
        break;
      case 7:
        text = const Text('SAT', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );
  FlTitlesData get titlesData => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
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
