import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/db_service.dart';
import '../widgets/completion_calendar.dart';
import 'add_habit_screen.dart';

class HabitDetailsScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  int _streak = 0;
  int _bestStreak = 0;
  double _successRate = 0.0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.habit.id == null) return;

    setState(() {
      _isLoading = true;
    });

    final streak = await DatabaseService.instance
        .getCurrentStreak(widget.habit.id!);
    final successRate = await DatabaseService.instance
        .getSuccessRate(widget.habit.id!);
    final weeklyData = await _getWeeklyData();
    
    // Reload habit to get updated best streak
    final updatedHabit = await DatabaseService.instance.getHabit(widget.habit.id!);

    setState(() {
      _streak = streak;
      _bestStreak = updatedHabit?.bestStreak ?? 0;
      _successRate = successRate;
      _weeklyData = weeklyData;
      _isLoading = false;
    });
  }

  Future<void> _editHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(habit: widget.habit),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<List<Map<String, dynamic>>> _getWeeklyData() async {
    if (widget.habit.id == null) return [];

    final today = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check if there's a completion for this specific date
      final completions = await DatabaseService.instance.getCompletionsForHabit(
        widget.habit.id!,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final completed = completions.any((c) => c.isCompleted);

      data.add({
        'date': date,
        'completed': completed,
        'dayName': DateFormat('E').format(date),
      });
    }

    return data;
  }

  Color _getColorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6C63FF);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water_drop':
        return Icons.water_drop;
      case 'local_dining':
        return Icons.local_dining;
      case 'bedtime':
        return Icons.bedtime;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'music_note':
        return Icons.music_note;
      case 'code':
        return Icons.code;
      case 'brush':
        return Icons.brush;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(widget.habit.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editHabit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      color: color.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getIconData(widget.habit.icon),
                                color: color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.habit.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.habit.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.habit.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stats Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Current Streak',
                            '$_streak',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Best Streak',
                            '$_bestStreak',
                            Icons.emoji_events,
                            Colors.amber,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Success Rate',
                            '${_successRate.toStringAsFixed(0)}%',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Weekly Progress Chart
                    const Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildWeeklyChart(color),
                    ),
                    const SizedBox(height: 24),
                    // Completion History
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._weeklyData.map((day) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: day['completed']
                                ? color.withValues(alpha: 0.2)
                                : Colors.grey[200],
                            child: Icon(
                              day['completed'] ? Icons.check : Icons.close,
                              color: day['completed'] ? color : Colors.grey,
                            ),
                          ),
                          title: Text(
                            DateFormat('EEEE, MMMM d').format(day['date']),
                            style: TextStyle(
                              fontWeight: day['completed']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: day['completed']
                              ? Icon(Icons.check_circle, color: color)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Today's Note
                    if (_weeklyData.isNotEmpty && _weeklyData.last['completed'] == true)
                      FutureBuilder<String?>(
                        future: DatabaseService.instance.getTodayCompletionNote(widget.habit.id!),
                        builder: (context, snapshot) {
                          final note = snapshot.data;
                          if (note == null || note.isEmpty) return const SizedBox.shrink();
                          
                          return Card(
                            color: color.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.note, color: color, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Today's Note",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    note,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    // Completion Calendar
                    CompletionCalendar(habit: widget.habit),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Color color) {
    if (_weeklyData.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _weeklyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _weeklyData[value.toInt()]['dayName'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: _weeklyData.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: day['completed'] ? 1.0 : 0.0,
                color: day['completed'] ? color : Colors.grey[300],
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

