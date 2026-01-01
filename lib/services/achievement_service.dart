import '../models/habit_model.dart';
import 'db_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementService {
  static final AchievementService instance = AchievementService._init();
  
  AchievementService._init();

  List<Achievement> getAllAchievements() {
    return [
      Achievement(
        id: 'first_habit',
        title: 'Getting Started',
        description: 'Create your first habit',
        icon: '🎯',
      ),
      Achievement(
        id: 'week_streak',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: '🔥',
      ),
      Achievement(
        id: 'month_streak',
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: '⭐',
      ),
      Achievement(
        id: 'century',
        title: 'Century Club',
        description: 'Reach 100 days on any habit',
        icon: '💯',
      ),
      Achievement(
        id: 'five_habits',
        title: 'Habit Collector',
        description: 'Create 5 habits',
        icon: '📚',
      ),
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: 'Complete all habits every day for a week',
        icon: '✨',
      ),
      Achievement(
        id: 'year_streak',
        title: 'Year Champion',
        description: 'Maintain a 365-day streak',
        icon: '🏆',
      ),
    ];
  }

  Future<List<Achievement>> checkAchievements() async {
    final allAchievements = getAllAchievements();
    final habits = await DatabaseService.instance.getAllHabits();
    final unlockedAchievements = <Achievement>[];

    // Check first habit
    if (habits.isNotEmpty) {
      unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'first_habit').copyWith(unlocked: true));
    }

    // Check 5 habits
    if (habits.length >= 5) {
      unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'five_habits').copyWith(unlocked: true));
    }

    // Check streaks for each habit
    for (var habit in habits) {
      if (habit.id == null) continue;
      
      final streak = await DatabaseService.instance.getCurrentStreak(habit.id!);
      final bestStreak = habit.bestStreak;

      if (streak >= 7 || bestStreak >= 7) {
        unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'week_streak').copyWith(unlocked: true));
      }
      if (streak >= 30 || bestStreak >= 30) {
        unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'month_streak').copyWith(unlocked: true));
      }
      if (bestStreak >= 100) {
        unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'century').copyWith(unlocked: true));
      }
      if (bestStreak >= 365) {
        unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'year_streak').copyWith(unlocked: true));
      }
    }

    // Check perfect week (all habits completed every day for 7 days)
    final perfectWeek = await _checkPerfectWeek(habits);
    if (perfectWeek) {
      unlockedAchievements.add(allAchievements.firstWhere((a) => a.id == 'perfect_week').copyWith(unlocked: true));
    }

    return unlockedAchievements.toSet().toList(); // Remove duplicates
  }

  Future<bool> _checkPerfectWeek(List<Habit> habits) async {
    if (habits.isEmpty) return false;
    
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      for (var habit in habits) {
        if (habit.id == null) continue;
        final completions = await DatabaseService.instance.getCompletionsForHabit(
          habit.id!,
          startDate: startOfDay,
          endDate: endOfDay,
        );
        final completed = completions.any((c) => c.isCompleted);
        if (!completed) return false;
      }
    }
    return true;
  }
}

extension AchievementExtension on Achievement {
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    bool? unlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

