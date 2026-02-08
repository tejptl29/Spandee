import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spendee/core/theme/theme_provider.dart';

class ExpenseChart extends StatefulWidget {
  final List<QueryDocumentSnapshot> expenses;
  final DateTime? selectedMonth;

  const ExpenseChart({super.key, required this.expenses, this.selectedMonth});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  final currencyFormat = NumberFormat('#,##,###');

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Aggregate expenses by day
    final Map<int, double> dailyTotals = {};
    double grandTotal = 0;
    final referenceDate = widget.selectedMonth ?? DateTime.now();
    final daysInMonth = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    ).day;

    for (var doc in widget.expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      if (date.month == referenceDate.month &&
          date.year == referenceDate.year) {
        final day = date.day;
        final amount = (data['amount'] as num).toDouble();
        dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;
        grandTotal += amount;
      }
    }

    // Calculate Average and Peak
    // If selectedMonth is in the past, use all days in month for average.
    // If it's the current month, use days passed so far.
    final now = DateTime.now();
    final int daysToDivideBy =
        (referenceDate.year == now.year && referenceDate.month == now.month)
        ? now.day
        : daysInMonth;

    final double averageDailySpend = grandTotal / daysToDivideBy;
    double peakSpend = 0;
    int peakDay = 0;

    final List<FlSpot> spots = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final amount = dailyTotals[day] ?? 0;
      spots.add(FlSpot(day.toDouble(), amount));
      if (amount > peakSpend) {
        peakSpend = amount;
        peakDay = day;
      }
    }

    double maxY = peakSpend * 1.3;
    if (maxY == 0) maxY = 1000;

    return Container(
      width: double.infinity,
      height: 380,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(30),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Spending",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Average: ₹${currencyFormat.format(averageDailySpend.round())}/day",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF16B888).withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "₹${currencyFormat.format(grandTotal.round())}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16B888),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(10),
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
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 1 ||
                            value > daysInMonth ||
                            value != value.toInt().toDouble()) {
                          return const SizedBox.shrink();
                        }
                        if (value % 7 != 0 && value != 1) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: averageDailySpend,
                      color: Colors.orange.withAlpha(100),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 10, bottom: 2),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (line) => "AVG",
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF16B888),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        bool isPeak = spot.x.toInt() == peakDay && spot.y > 0;
                        return FlDotCirclePainter(
                          radius: isPeak ? 5 : 0,
                          color: const Color(0xFF16B888),
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF16B888).withAlpha(40),
                          const Color(0xFF16B888).withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF16B888),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '₹${currencyFormat.format(barSpot.y.round())}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Day ${barSpot.x.toInt()}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIndicator(Colors.orange.shade300, "Average"),
              const SizedBox(width: 20),
              _buildIndicator(const Color(0xFF16B888), "Total Spend"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
