import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class FuelConsumptionChart extends StatelessWidget {
  final List<FuelTransaction> refuelingData;

  const FuelConsumptionChart({super.key, required this.refuelingData});

  @override
  Widget build(BuildContext context) {
    // Get last 10 transactions with volume data, reversed to show recent to old (left to right)
    final chartData = refuelingData
        .where((t) => t.volume > 0)
        .take(10)
        .toList()
        .reversed
        .toList();
    
    if (chartData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Fuel Volume Trend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No consumption data available for chart',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Create volume chart data
    final spots = <FlSpot>[];
    double minVolume = double.infinity;
    double maxVolume = 0;

    for (int i = 0; i < chartData.length; i++) {
      final transaction = chartData[i];
      final volume = transaction.volume;
      
      spots.add(FlSpot(i.toDouble(), volume));
      
      if (volume < minVolume) minVolume = volume;
      if (volume > maxVolume) maxVolume = volume;
    }

    // Add some padding to the Y-axis range and ensure minimum range
    final range = maxVolume - minVolume;
    final yPadding = range > 0 ? range * 0.1 : maxVolume * 0.1;
    final minY = (minVolume - yPadding).clamp(0.0, double.infinity);
    final maxY = maxVolume + yPadding;
    
    // Ensure minimum Y-axis range to prevent division by zero
    final yRange = maxY - minY;
    final adjustedMaxY = yRange > 0 ? maxY : minY + (minY > 0 ? minY * 0.2 : 10.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Fuel Volume Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Last ${chartData.length} refuelings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (adjustedMaxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          final date = chartData[index].date;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (adjustedMaxY - minY) / 4,
                      reservedSize: 50,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}L',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: minY,
                maxY: adjustedMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.8),
                        Colors.blue.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.1),
                          Colors.blue.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final index = barSpot.x.toInt();
                        if (index >= 0 && index < chartData.length) {
                          final transaction = chartData[index];
                          final volume = barSpot.y;
                          return LineTooltipItem(
                            '${DateFormat('MMM dd').format(transaction.date)}\n${volume.toStringAsFixed(1)}L',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}