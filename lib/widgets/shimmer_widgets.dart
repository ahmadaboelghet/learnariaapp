import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _Box({this.width, required this.height, this.radius = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// Mirrors GlassContainer exactly: border + bg + shadow
class _ShimmerCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  const _ShimmerCard({
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFE5E8EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Shimmer wrapper — adapts base/highlight to dark/light theme
class _Wrap extends StatelessWidget {
  final Widget child;
  const _Wrap({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2028) : const Color(0xFFE8EAEE),
      highlightColor: isDark ? const Color(0xFF2C303C) : const Color(0xFFF6F7F9),
      period: const Duration(milliseconds: 1100),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN — mirrors _buildDashboardContent exactly
// ─────────────────────────────────────────────────────────────────────────────

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Wrap(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. User info row (avatar + greeting + notification icon) ──
            _userInfoRow(),
            const SizedBox(height: 20),

            // ── 2. "Reports" section title ──
            const _Box(width: 80, height: 18),
            const SizedBox(height: 10),

            // ── 2b. Two summary cards (assignments + attendance) ──
            Row(
              children: [
                Expanded(child: _summaryCard()),
                const SizedBox(width: 15),
                Expanded(child: _summaryCard()),
              ],
            ),

            // ── 3. Monthly Payment section ──
            const SizedBox(height: 20),
            const _Box(width: 180, height: 18),
            const SizedBox(height: 10),

            // Month picker strip (h:50, pill chips)
            _monthPickerStrip(),
            const SizedBox(height: 8),

            // Payment rows × 2
            _paymentRow(),
            const SizedBox(height: 10),
            _paymentRow(),

            // ── 4. "Today's Courses" + calendar strip ──
            const SizedBox(height: 25),
            const _Box(width: 140, height: 18),

            // Calendar strip (h:90, 7 cells × w:60)
            _calendarStrip(),
            const SizedBox(height: 5),

            // Course cards × 2
            _courseCard(),
            const SizedBox(height: 10),
            _courseCard(),

            // ── 5. "Assignments by Subject" horizontal list ──
            const SizedBox(height: 20),
            const _Box(width: 180, height: 18),
            const SizedBox(height: 10),
            _horizontalSubjectList(),

            // ── 6. "Attendance by Subject" horizontal list ──
            const SizedBox(height: 20),
            const _Box(width: 170, height: 18),
            const SizedBox(height: 10),
            _horizontalSubjectList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Row: CircleAvatar (r:24) + two text lines + notification icon
  Widget _userInfoRow() => Row(
        children: [
          const _Box(width: 48, height: 48, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Box(width: double.infinity, height: 16),
                SizedBox(height: 6),
                _Box(width: 140, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _Box(width: 32, height: 32, radius: 16),
        ],
      );

  // GlassContainer summary card: title + big value + small description
  Widget _summaryCard() => _ShimmerCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Box(width: 90, height: 14),
            SizedBox(height: 8),
            _Box(width: 110, height: 20),
            SizedBox(height: 4),
            _Box(width: 80, height: 12),
          ],
        ),
      );

  // Horizontal row of month pills (h:50)
  Widget _monthPickerStrip() => SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            6,
            (_) => Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      );

  // Payment row: icon(24) + 2 text lines + amount column
  Widget _paymentRow() => _ShimmerCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const _Box(width: 24, height: 24, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Box(width: double.infinity, height: 14),
                  SizedBox(height: 4),
                  _Box(width: 100, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _Box(width: 60, height: 14),
                SizedBox(height: 4),
                _Box(width: 40, height: 10),
              ],
            ),
          ],
        ),
      );

  // Calendar strip: 7 cells × (w:60, h:90)
  Widget _calendarStrip() => Container(
        height: 90,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            7,
            (_) => Container(
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Box(width: 28, height: 11),
                  SizedBox(height: 6),
                  _Box(width: 22, height: 20),
                ],
              ),
            ),
          ),
        ),
      );

  // Course card: full-width GlassContainer — text left, badge right
  Widget _courseCard() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ShimmerCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Box(width: 140, height: 14),
                    SizedBox(height: 4),
                    _Box(width: 100, height: 11),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      );

  // Horizontal subject list: h:160, cards w:170
  Widget _horizontalSubjectList() => SizedBox(
        height: 164, // same as actual ListView height (160) + bottom padding
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            3,
            (_) => Container(
              width: 170,
              margin: const EdgeInsets.only(right: 14, bottom: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _Box(width: 32, height: 32, radius: 10),
                      _Box(width: 12, height: 12, radius: 4),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _Box(width: 100, height: 14),
                  const SizedBox(height: 4),
                  const _Box(width: 70, height: 11),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _Box(width: 36, height: 9),
                          SizedBox(height: 3),
                          _Box(width: 44, height: 18),
                        ],
                      ),
                      const _Box(width: 40, height: 40, radius: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORTS SCREEN — mirrors _buildStudentLevelHeaderCard, _buildAnalyticsCard,
//  _buildSubjectInsightsList, _buildPerformanceChartSection exactly
// ─────────────────────────────────────────────────────────────────────────────

class ReportsShimmer extends StatelessWidget {
  const ReportsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Wrap(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Student header card ──
            // GlassContainer: name + subtitle on left, XX% + label on right
            _ShimmerCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Box(width: 140, height: 20),
                      SizedBox(height: 4),
                      _Box(width: 180, height: 12),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _Box(width: 55, height: 22),
                      SizedBox(height: 4),
                      _Box(width: 70, height: 10),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 2. Two analytics cards side-by-side ──
            // Each: label row (text + icon) + big %, LinearProgressIndicator
            Row(
              children: [
                Expanded(child: _analyticsCard()),
                const SizedBox(width: 14),
                Expanded(child: _analyticsCard()),
              ],
            ),
            const SizedBox(height: 25),

            // ── 3. Subject insights section title ──
            const _Box(width: 160, height: 18),
            const SizedBox(height: 10),

            // Subject insight rows × 3
            _subjectInsightRow(),
            _subjectInsightRow(),
            _subjectInsightRow(),

            // ── 4. Chart section title + chart card ──
            const _Box(width: 170, height: 18),
            const SizedBox(height: 10),

            // Chart: GlassContainer h:200 with bar stubs
            _ShimmerCard(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bar(height: 130),
                        _bar(height: 90),
                        _bar(height: 155),
                        _bar(height: 70),
                        _bar(height: 110),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // X-axis labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      5,
                      (_) => const _Box(width: 36, height: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Analytics card: label+icon row, big %, LinearProgressIndicator stub
  Widget _analyticsCard() => _ShimmerCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Box(width: 80, height: 14),
                _Box(width: 18, height: 18, radius: 4),
              ],
            ),
            const SizedBox(height: 12),
            const _Box(width: 60, height: 26),
            const SizedBox(height: 6),
            // LinearProgressIndicator placeholder
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );

  // Subject insight row: subject + teacher on left, two % columns on right
  Widget _subjectInsightRow() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Box(width: 120, height: 15),
                    SizedBox(height: 4),
                    _Box(width: 90, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Overall % column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _Box(width: 44, height: 15),
                  SizedBox(height: 3),
                  _Box(width: 50, height: 10),
                ],
              ),
              const SizedBox(width: 16),
              // Attendance % column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _Box(width: 44, height: 15),
                  SizedBox(height: 3),
                  _Box(width: 60, height: 10),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _bar({required double height}) => Container(
        width: 16,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFICATIONS SCREEN shimmer
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsShimmer extends StatelessWidget {
  const NotificationsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Wrap(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ShimmerCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Box(width: 42, height: 42, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Box(width: double.infinity, height: 13),
                    SizedBox(height: 6),
                    _Box(width: 220, height: 11),
                    SizedBox(height: 6),
                    _Box(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
