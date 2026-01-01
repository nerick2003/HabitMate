class Habit {
  int? id;
  int userId; // User ID who owns this habit
  String name;
  String description;
  String frequency; // 'daily' or 'weekly'
  List<String> reminderTimes; // List of times in HH:mm format
  DateTime createdAt;
  String color; // Hex color code
  String icon; // Icon name/identifier
  String category; // Category name (e.g., 'Health', 'Work', 'Personal')
  int bestStreak; // Best streak ever achieved

  Habit({
    this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.frequency = 'daily',
    this.reminderTimes = const [],
    DateTime? createdAt,
    this.color = '#6C63FF',
    this.icon = 'fitness_center',
    this.category = 'General',
    this.bestStreak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'reminderTimes': reminderTimes.join(','),
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'icon': icon,
      'category': category,
      'bestStreak': bestStreak,
    };
  }

  // Create from Map (from database)
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 1, // Default to 1 for backward compatibility
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'daily',
      reminderTimes: (map['reminderTimes'] as String? ?? '')
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      color: map['color'] as String? ?? '#6C63FF',
      icon: map['icon'] as String? ?? 'fitness_center',
      category: map['category'] as String? ?? 'General',
      bestStreak: (map['bestStreak'] as int?) ?? 0,
    );
  }

  Habit copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? frequency,
    List<String>? reminderTimes,
    DateTime? createdAt,
    String? color,
    String? icon,
    String? category,
    int? bestStreak,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

class HabitCompletion {
  int? id;
  int habitId;
  int userId; // User ID who owns this completion
  DateTime completedAt;
  bool isCompleted;
  String note; // Optional note for this completion

  HabitCompletion({
    this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.isCompleted = true,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'note': note,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      userId: (map['userId'] as int?) ?? 1, // Default to 1 for backward compatibility
      completedAt: DateTime.parse(map['completedAt'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      note: map['note'] as String? ?? '',
    );
  }
}

