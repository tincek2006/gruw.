import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_shell.dart';

class RunsScreen extends StatefulWidget {
  const RunsScreen({super.key});

  @override
  State<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends State<RunsScreen> {
  DateTime _visibleMonth = DateTime(2026, 7);

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Runs',
      activeTab: AppTab.runs,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _CalendarCard(
              month: _visibleMonth,
              onPrevMonth: () => _changeMonth(-1),
              onNextMonth: () => _changeMonth(1),
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Text('Your runs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(width: 8),
                Icon(Icons.add_circle_outline, color: AppColors.textPrimary),
              ],
            ),
            const SizedBox(height: 16),
            const _RunHistoryCarousel(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _CalendarCard({
    required this.month,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // TODO: replace with real activity/planned-activity data from Strava history.
    const activityDays = {1, 4, 6, 9, 10, 11, 13, 15};
    const plannedDays = {1, 6, 8, 13, 15};
    const today = 8;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plan 26', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  IconButton(
                    onPressed: onPrevMonth,
                    icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  ),
                  Text(_monthNames[month.month - 1], style: const TextStyle(color: AppColors.textSecondary)),
                  IconButton(
                    onPressed: onNextMonth,
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              final day = i + 1;
              final isToday = day == today;
              final hasActivity = activityDays.contains(day);
              final isPlanned = plannedDays.contains(day);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? Border.all(color: AppColors.accentPink, width: 2)
                      : Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text('$day', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (hasActivity)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.star_rounded, size: 10, color: AppColors.accentPink),
                      ),
                    if (isPlanned)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.star_rounded, size: 14, color: AppColors.accentPink),
                  SizedBox(width: 4),
                  Text('activity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  SizedBox(width: 12),
                  Icon(Icons.circle, size: 8, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('planned activity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Change plan', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunHistoryCarousel extends StatelessWidget {
  const _RunHistoryCarousel();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with real run history from Strava's /athlete/activities endpoint.
    const runs = [
      {'date': '22/5/2026', 'distanceKm': 5, 'timeMin': 28, 'paceMinPerKm': '5:36', 'cadenceSpm': 158},
      {'date': '20/5/2026', 'distanceKm': 8, 'timeMin': 44, 'paceMinPerKm': '5:30', 'cadenceSpm': 162},
    ];

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: runs.length,
        itemBuilder: (context, i) {
          final r = runs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Run', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(r['date'] as String, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _StatBlock(label: 'Distance', value: '${r['distanceKm']}km'),
                      const SizedBox(width: 20),
                      Container(width: 1, height: 50, color: AppColors.cardBorder),
                      const SizedBox(width: 20),
                      _StatBlock(label: 'Pace-min/km', value: r['paceMinPerKm'] as String),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _StatBlock(label: 'Time', value: '${r['timeMin']}min'),
                      const SizedBox(width: 20),
                      Container(width: 1, height: 50, color: AppColors.cardBorder),
                      const SizedBox(width: 20),
                      _StatBlock(label: 'Cadence-SPM', value: '${r['cadenceSpm']}spm'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
