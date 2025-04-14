import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmotionalTrendGraph extends StatelessWidget {
  final Map<int, int> sadEmotionalData; // map of day:count
  final Map<int, int> angerEmotionalData;
  
  const EmotionalTrendGraph({
    Key? key, 
    required this.angerEmotionalData,
    required this.sadEmotionalData
  }) : super(key: key);

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

  Widget getTitles(double value, TitleMeta? meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
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