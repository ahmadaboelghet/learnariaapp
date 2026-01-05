import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_card.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await FirestoreApi().fetchDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final List<TeacherReport> reports = _dashboardData?.reportsByTeacher ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLocalizations.progressReport,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appLocalizations.performanceOverview,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              // 1. إصلاح إعدادات الـ Tooltip
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  // تم استبدال tooltipBgColor بـ getTooltipColor
                                  getTooltipColor: (group) => theme.cardColor,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        // التأكد من أن الإندكس موجود داخل القائمة
                                        if (group.x.toInt() >= reports.length)
                                          return null;

                                        String subject =
                                            reports[group.x.toInt()].subject;
                                        return BarTooltipItem(
                                          '$subject\n',
                                          TextStyle(
                                            color: theme
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '${rod.toY.toInt()}%',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 &&
                                          index < reports.length) {
                                        String label =
                                            reports[index].subject.length > 3
                                            ? reports[index].subject.substring(
                                                0,
                                                3,
                                              )
                                            : reports[index].subject;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 20 == 0) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: theme.dividerColor.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              // 2. إصلاح القائمة (List) باستخدام List.generate
                              barGroups: List.generate(reports.length, (index) {
                                final grades = reports[index].grades
                                    .where((g) => g.score != null)
                                    .toList();
                                double avgScore = 0;
                                if (grades.isNotEmpty) {
                                  double total = grades.fold(
                                    0,
                                    (sum, item) => sum + (item.score ?? 0),
                                  );
                                  avgScore = total / grades.length;
                                }

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: avgScore,
                                      color: AppColors.primary,
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY: 100,
                                            color:
                                                theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white10
                                                : Colors.grey.shade200,
                                          ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
