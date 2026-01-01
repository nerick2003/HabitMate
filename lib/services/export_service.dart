import 'dart:convert';
import '../models/habit_model.dart';
import 'db_service.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  
  ExportService._init();

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

  String exportToJSON() {
    // This would be called after exportAllData
    // For now, return empty - will be used with file picker
    return '';
  }

  String exportToCSV() {
    // CSV export format
    // For now, return empty - will be used with file picker
    return '';
  }

  Future<String> generateCSV() async {
    final data = await exportAllData();
    final habits = (data['habits'] as List).map((h) => Habit.fromMap(h)).toList();
    final completions = (data['completions'] as List)
        .map((c) => HabitCompletion.fromMap(c))
        .toList();

    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Habit Name,Category,Completed Date,Completed,Note');
    
    // Data rows
    for (var completion in completions) {
      final habit = habits.firstWhere(
        (h) => h.id == completion.habitId,
        orElse: () => Habit(userId: completion.userId, name: 'Unknown'),
      );
      
      final date = DateTime.parse(completion.completedAt.toIso8601String());
      buffer.writeln(
        '"${habit.name}","${habit.category}",'
        '${date.toIso8601String()},'
        '${completion.isCompleted ? "Yes" : "No"},'
        '"${completion.note.replaceAll('"', '""')}"',
      );
    }
    
    return buffer.toString();
  }

  Future<String> generateJSON() async {
    final data = await exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

