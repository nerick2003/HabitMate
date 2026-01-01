import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/db_service.dart';
import '../utils/color_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final color = ColorUtils.fromHex(widget.habit.color);
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
    final monthInfo = _calculateMonthInfo(monthStart);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(monthStart),
          _buildCalendarGrid(monthStart, today, color, monthInfo),
        ],
      ),
    );
  }

  /// Calculates month information (days in month, first weekday, etc.)
  Map<String, dynamic> _calculateMonthInfo(DateTime monthStart) {
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = monthStart.weekday;
    final totalCells = firstWeekday - 1 + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return {
      'daysInMonth': daysInMonth,
      'firstWeekday': firstWeekday,
      'weeks': weeks,
    };
  }

  /// Builds the month header
  Widget _buildMonthHeader(DateTime monthStart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        DateFormat('MMMM yyyy').format(monthStart),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds the calendar grid
  Widget _buildCalendarGrid(
    DateTime monthStart,
    DateTime today,
    Color color,
    Map<String, dynamic> monthInfo,
  ) {
    final daysInMonth = monthInfo['daysInMonth'] as int;
    final firstWeekday = monthInfo['firstWeekday'] as int;
    final weeks = monthInfo['weeks'] as int;

    return GridView.builder(
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
        final day = _calculateDayFromIndex(index, firstWeekday, daysInMonth);
        if (day == null) {
          return const SizedBox.shrink();
        }

        final date = DateTime(monthStart.year, monthStart.month, day);
        return _buildDayCell(context, date, today, color);
      },
    );
  }

  /// Calculates the day number from grid index
  int? _calculateDayFromIndex(int index, int firstWeekday, int daysInMonth) {
    final dayOfWeek = index % 7;
    final week = index ~/ 7;
    final day = week * 7 + dayOfWeek - (firstWeekday - 1) + 1;

    if (day < 1 || day > daysInMonth) {
      return null;
    }
    return day;
  }

  /// Builds a single day cell
  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    DateTime today,
    Color color,
  ) {
    final isCompleted = _completions[date] ?? false;
    final isToday = _isSameDay(date, today);
    final isFuture = date.isAfter(today);

    return Container(
      decoration: BoxDecoration(
        color: _getDayCellColor(context, isCompleted, isToday, color),
        borderRadius: BorderRadius.circular(4),
        border: isToday ? Border.all(color: color, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: _getDayCellTextStyle(context, isCompleted, isToday, isFuture, color),
        ),
      ),
    );
  }

  /// Checks if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Gets the background color for a day cell
  Color _getDayCellColor(
    BuildContext context,
    bool isCompleted,
    bool isToday,
    Color color,
  ) {
    if (isCompleted) return color;
    if (isToday) return color.withValues(alpha: 0.2);
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// Gets the text style for a day cell
  TextStyle _getDayCellTextStyle(
    BuildContext context,
    bool isCompleted,
    bool isToday,
    bool isFuture,
    Color color,
  ) {
    Color textColor;
    if (isCompleted) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = color;
    } else if (isFuture) {
      textColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4) ??
          Colors.grey;
    } else {
      textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }

    return TextStyle(
      fontSize: 12,
      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
      color: textColor,
    );
  }
}

