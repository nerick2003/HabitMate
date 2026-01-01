import 'dart:convert';
import '../models/habit_model.dart';
import 'db_service.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  
  ExportService._init();

  /// Exports all habit data including habits and completions
  Future<Map<String, dynamic>> exportAllData() async {
    final habits = await DatabaseService.instance.getAllHabits();
    final allCompletions = <HabitCompletion>[];

    for (var habit in habits) {
      if (habit.id != null) {
        final completions = await DatabaseService.instance.getCompletionsForHabit(habit.id!);
        allCompletions.addAll(completions);
      }
    }

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'completions': allCompletions.map((c) => c.toMap()).toList(),
    };
  }

  /// Generates CSV format export data
  Future<String> generateCSV() async {
    final data = await exportAllData();
    final habits = (data['habits'] as List).map((h) => Habit.fromMap(h)).toList();
    final completions = (data['completions'] as List)
        .map((c) => HabitCompletion.fromMap(c))
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('Habit Name,Category,Completed Date,Completed,Note');
    
    for (var completion in completions) {
      final habit = _findHabitForCompletion(habits, completion);
      final csvRow = _formatCompletionAsCSV(habit, completion);
      buffer.writeln(csvRow);
    }
    
    return buffer.toString();
  }

  /// Generates JSON format export data
  Future<String> generateJSON() async {
    final data = await exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Finds the habit associated with a completion
  Habit _findHabitForCompletion(List<Habit> habits, HabitCompletion completion) {
    return habits.firstWhere(
      (h) => h.id == completion.habitId,
      orElse: () => Habit(userId: completion.userId, name: 'Unknown'),
    );
  }

  /// Formats a completion as a CSV row
  String _formatCompletionAsCSV(Habit habit, HabitCompletion completion) {
    final date = DateTime.parse(completion.completedAt.toIso8601String());
    final escapedNote = completion.note.replaceAll('"', '""');
    final completedStatus = completion.isCompleted ? 'Yes' : 'No';
    
    return '"${habit.name}","${habit.category}",'
        '${date.toIso8601String()},'
        '$completedStatus,'
        '"$escapedNote"';
  }
}

