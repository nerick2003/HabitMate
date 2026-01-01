import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/db_service.dart';

class CompletionCalendar extends StatefulWidget {
  final Habit habit;
  final int daysToShow;

  const CompletionCalendar({
    super.key,
    required this.habit,
    this.daysToShow = 365,
  });

  @override
  State<CompletionCalendar> createState() => _CompletionCalendarState();
}

class _CompletionCalendarState extends State<CompletionCalendar> {
  Map<DateTime, bool> _completions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    if (widget.habit.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: widget.daysToShow));

    final completions = await DatabaseService.instance.getCompletionsForHabit(
      widget.habit.id!,
      startDate: startDate,
      endDate: endDate,
    );

    final Map<DateTime, bool> completionMap = {};
    for (var completion in completions) {
      if (completion.isCompleted) {
        final date = DateTime(
          completion.completedAt.year,
          completion.completedAt.month,
          completion.completedAt.day,
        );
        completionMap[date] = true;
      }
    }

    setState(() {
      _completions = completionMap;
      _isLoading = false;
    });
  }

  Color _getColorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final color = _getColorFromHex(widget.habit.color);
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: widget.daysToShow));
    
    // Generate list of months to display
    final months = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, 1);
    while (current.isBefore(today) || current.month == today.month) {
      months.add(DateTime(current.year, current.month, 1));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Calendar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...months.map((monthStart) {
          return _buildMonthView(monthStart, today, color);
        }).toList(),
      ],
    );
  }

  Widget _buildMonthView(DateTime monthStart, DateTime today, Color color) {
    final firstDay = monthStart;
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Find the first day of week for this month
    final firstWeekday = firstDay.weekday;
    
    // Calculate how many weeks we need
    final totalCells = firstWeekday - 1 + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              DateFormat('MMMM yyyy').format(monthStart),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: weeks * 7,
            itemBuilder: (context, index) {
              final dayOfWeek = index % 7;
              final week = index ~/ 7;
              final day = week * 7 + dayOfWeek - (firstWeekday - 1) + 1;

              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(monthStart.year, monthStart.month, day);
              final isCompleted = _completions[date] ?? false;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isFuture = date.isAfter(today);

              return Container(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? color
                      : isToday
                          ? color.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? Colors.white
                          : isToday
                              ? color
                              : isFuture
                                  ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

