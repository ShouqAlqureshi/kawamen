import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PerformanceMetricsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أداء كشف المشاعر',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('performanceMetrics')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات أداء متاحة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ستظهر البيانات بعد استخدام كشف المشاعر',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final metrics = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Calculate averages
          final avgRecording = _calculateAverage(metrics, 'recordingTimeMs');
          final avgProcessing = _calculateAverage(metrics, 'processingTimeMs');
          final avgClassification =
              _calculateAverage(metrics, 'classificationTimeMs');
          final avgNotification =
              _calculateAverage(metrics, 'notificationTimeMs');
          final avgTotal = _calculateAverage(metrics, 'totalTimeMs');

          // Calculate requirement stats
          final meetsRequirement =
              metrics.where((m) => (m['totalTimeMs'] as num) <= 10000).length;
          final requirementPercentage =
              (meetsRequirement / metrics.length) * 100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  context,
                  avgTotal,
                  requirementPercentage,
                  avgRecording,
                  avgProcessing,
                  avgClassification,
                  avgNotification,
                ),
                SizedBox(height: 24),
                _buildPerformanceBreakdownSection(
                  context,
                  avgRecording,
                  avgProcessing,
                  avgClassification,
                  avgNotification,
                ),
                SizedBox(height: 24),
                _buildTimelineSection(context, metrics),
                SizedBox(height: 24),
                _buildDeviceComparisonSection(context, metrics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double avgTotal,
    double requirementPercentage,
    double avgRecording,
    double avgProcessing,
    double avgClassification,
    double avgNotification,
  ) {
    final meetsRequirement = avgTotal <= 10000;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الأداء',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متوسط وقت الكشف',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${avgTotal.toStringAsFixed(0)} ms',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: meetsRequirement ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(avgTotal / 1000).toStringAsFixed(1)} ثواني',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularProgressIndicator(
                          value: requirementPercentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            requirementPercentage > 80
                                ? Colors.green
                                : requirementPercentage > 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${requirementPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'متطابق',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'متطلب الأداء: كشف المشاعر خلال 10 ثواني',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              meetsRequirement ? 'المتطلب محقق ✓' : 'المتطلب غير محقق ✗',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: meetsRequirement ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBreakdownSection(
    BuildContext context,
    double avgRecording,
    double avgProcessing,
    double avgClassification,
    double avgNotification,
  ) {
    final totalAvg =
        avgRecording + avgProcessing + avgClassification + avgNotification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفصيل مراحل الأداء',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 200,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: totalAvg,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      switch (value.toInt()) {
                        case 0:
                          text = 'التسجيل';
                          break;
                        case 1:
                          text = 'المعالجة';
                          break;
                        case 2:
                          text = 'التصنيف';
                          break;
                        case 3:
                          text = 'الإشعار';
                          break;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: totalAvg / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()} ms',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _buildBarGroup(0, avgRecording, Colors.blue),
                _buildBarGroup(1, avgProcessing, Colors.green),
                _buildBarGroup(2, avgClassification, Colors.orange),
                _buildBarGroup(3, avgNotification, Colors.purple),
              ],
              gridData: FlGridData(
                show: true,
                horizontalInterval: totalAvg / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildPerformanceBreakdownLegend(
          avgRecording,
          avgProcessing,
          avgClassification,
          avgNotification,
          totalAvg,
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double value,
    Color color,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 30,
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildPerformanceBreakdownLegend(
    double recording,
    double processing,
    double classification,
    double notification,
    double total,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLegendItem(
              'التسجيل الصوتي',
              recording,
              Colors.blue,
              (recording / total) * 100,
            ),
            SizedBox(height: 8),
            _buildLegendItem(
              'معالجة API',
              processing,
              Colors.green,
              (processing / total) * 100,
            ),
            SizedBox(height: 8),
            _buildLegendItem(
              'تصنيف المشاعر',
              classification,
              Colors.orange,
              (classification / total) * 100,
            ),
            SizedBox(height: 8),
            _buildLegendItem(
              'إنشاء الإشعارات',
              notification,
              Colors.purple,
              (notification / total) * 100,
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الوقت الإجمالي:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} ms (${(total / 1000).toStringAsFixed(1)} ثواني)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    double value,
    Color color,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} ms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(
    BuildContext context,
    List<Map<String, dynamic>> metrics,
  ) {
    // Only take the last 10 entries
    final recentMetrics = metrics.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل الكشف الأخير',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(0)} ms',
                        TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < recentMetrics.length) {
                        final timestamp = DateTime.parse(
                            recentMetrics[index]['timestamp'] as String);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('HH:mm').format(timestamp),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2000,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()} ms',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 2000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              lineBarsData: [
                _buildLineChartBarData(
                    recentMetrics, 'totalTimeMs', Colors.red),
                _buildLineChartBarData(
                    recentMetrics, 'recordingTimeMs', Colors.blue),
                _buildLineChartBarData(
                    recentMetrics, 'processingTimeMs', Colors.green),
              ],
              // Add horizontal threshold line for 10-second requirement
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 10000,
                    color: Colors.red.withOpacity(0.7),
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.only(right: 8, bottom: 4),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      labelResolver: (_) => 'الحد: 10 ثواني',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimelineLegendItem('الوقت الكلي', Colors.red),
            SizedBox(width: 24),
            _buildTimelineLegendItem('التسجيل', Colors.blue),
            SizedBox(width: 24),
            _buildTimelineLegendItem('المعالجة', Colors.green),
          ],
        ),
      ],
    );
  }

  LineChartBarData _buildLineChartBarData(
    List<Map<String, dynamic>> metrics,
    String field,
    Color color,
  ) {
    final spots = List.generate(metrics.length, (index) {
      return FlSpot(
        index.toDouble(),
        (metrics[index][field] as num).toDouble(),
      );
    });

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildTimelineLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceComparisonSection(
    BuildContext context,
    List<Map<String, dynamic>> metrics,
  ) {
    // Group metrics by device
    final deviceGroups = <String, List<Map<String, dynamic>>>{};

    for (final metric in metrics) {
      final deviceModel = metric['deviceModel'] as String? ?? 'Unknown';
      if (!deviceGroups.containsKey(deviceModel)) {
        deviceGroups[deviceModel] = [];
      }
      deviceGroups[deviceModel]!.add(metric);
    }

    // Calculate average total time for each device
    final deviceAverages = <String, double>{};
    final deviceRequirementMet = <String, int>{};
    final deviceCounts = <String, int>{};

    deviceGroups.forEach((device, deviceMetrics) {
      final totalSum = deviceMetrics.fold<double>(
        0,
        (sum, metric) => sum + (metric['totalTimeMs'] as num).toDouble(),
      );

      final metCount =
          deviceMetrics.where((m) => (m['totalTimeMs'] as num) <= 10000).length;

      deviceAverages[device] = totalSum / deviceMetrics.length;
      deviceRequirementMet[device] = metCount;
      deviceCounts[device] = deviceMetrics.length;
    });

    if (deviceGroups.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مقارنة الأجهزة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: deviceAverages.entries.map((entry) {
                final device = entry.key;
                final avgTime = entry.value;
                final metCount = deviceRequirementMet[device] ?? 0;
                final totalCount = deviceCounts[device] ?? 1;
                final successRate = (metCount / totalCount) * 100;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        device,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$totalCount عمليات كشف',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${avgTime.toStringAsFixed(0)} ms',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: avgTime <= 10000 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    LinearProgressIndicator(
                      value: successRate / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        successRate > 80
                            ? Colors.green
                            : successRate > 50
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${successRate.toStringAsFixed(0)}% ضمن المتطلبات',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    if (entry.key != deviceAverages.keys.last)
                      Divider(height: 24),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateAverage(List<Map<String, dynamic>> metrics, String field) {
    if (metrics.isEmpty) return 0;

    final sum = metrics.fold<double>(
      0,
      (sum, metric) => sum + (metric[field] as num).toDouble(),
    );

    return sum / metrics.length;
  }
}
