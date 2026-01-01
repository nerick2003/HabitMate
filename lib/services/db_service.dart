import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/habit_model.dart';
import 'user_service.dart';

// Conditional imports for web
import 'storage_stub.dart'
    if (dart.library.html) 'storage_web.dart'
    if (dart.library.io) 'storage_mobile.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static bool _webInitialized = false;

  DatabaseService._init();

  // Helper method to get current user ID
  Future<int?> _getCurrentUserId() async {
    final currentUser = await UserService.instance.getCurrentUser();
    return currentUser?.id;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database not available on web. Use web-specific methods.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _initWebDB() async {
    if (_webInitialized) return;
    if (!kIsWeb) return;
    
    final initialized = WebStorage.containsKey('habits_initialized');
    if (!initialized) {
      // Initialize with empty data
      await WebStorage.setString('habits', '[]');
      await WebStorage.setString('completions', '[]');
      await WebStorage.setString('habits_initialized', 'true');
    }
    _webInitialized = true;
  }

  Future<void> _createDB(Database db, int version) async {
    // Habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        frequency TEXT NOT NULL,
        reminderTimes TEXT,
        createdAt TEXT NOT NULL,
        color TEXT,
        icon TEXT,
        category TEXT,
        bestStreak INTEGER DEFAULT 0
      )
    ''');

    // Completions table
    await db.execute('''
      CREATE TABLE completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries
    await db.execute('''
      CREATE INDEX idx_completions_habit_date 
      ON completions(habitId, completedAt)
    ''');
    await db.execute('''
      CREATE INDEX idx_habits_user 
      ON habits(userId)
    ''');
    await db.execute('''
      CREATE INDEX idx_completions_user 
      ON completions(userId)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN category TEXT DEFAULT "General"');
        await db.execute('ALTER TABLE habits ADD COLUMN bestStreak INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE completions ADD COLUMN note TEXT DEFAULT ""');
      } catch (e) {
        // Columns might already exist, ignore
        print('Migration error (may be expected): $e');
      }
    }
    if (oldVersion < 3) {
      // Add userId columns for version 3 (multi-user support)
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN userId INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE completions ADD COLUMN userId INTEGER DEFAULT 1');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_user ON habits(userId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_completions_user ON completions(userId)');
      } catch (e) {
        print('Migration error (may be expected): $e');
      }
    }
  }

  // Habit CRUD operations
  Future<int> insertHabit(Habit habit) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    if (kIsWeb) {
      return await _insertHabitWeb(habit);
    }
    final db = await database;
    final map = habit.toMap();
    // Ensure userId is set
    map['userId'] = userId;
    // Remove id for new inserts (let SQLite auto-generate it)
    map.remove('id');
    return await db.insert('habits', map);
  }

  Future<int> _insertHabitWeb(Habit habit) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    await _initWebDB();
    final userKey = 'habits_$userId';
    final habitsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> habits = json.decode(habitsJson);
    
    // Generate new ID
    int newId = 1;
    if (habits.isNotEmpty) {
      final maxId = habits.map((h) => h['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
      newId = maxId + 1;
    }
    
    habit.id = newId;
    habit.userId = userId;
    habits.add(habit.toMap());
    
    await WebStorage.setString(userKey, json.encode(habits));
    return newId;
  }

  Future<List<Habit>> getAllHabits() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return [];
    }
    
    if (kIsWeb) {
      return await _getAllHabitsWeb();
    }
    final db = await database;
    final result = await db.query(
      'habits',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> _getAllHabitsWeb() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return [];
    }
    
    await _initWebDB();
    final userKey = 'habits_$userId';
    final habitsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> habits = json.decode(habitsJson);
    
    final habitList = habits.map((map) => Habit.fromMap(Map<String, dynamic>.from(map))).toList();
    // Sort by createdAt descending
    habitList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return habitList;
  }

  Future<Habit?> getHabit(int id) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return null;
    }
    
    if (kIsWeb) {
      final habits = await _getAllHabitsWeb();
      try {
        return habits.firstWhere((h) => h.id == id && h.userId == userId);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final result = await db.query(
      'habits',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    if (result.isEmpty) return null;
    return Habit.fromMap(result.first);
  }

  Future<int> updateHabit(Habit habit) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    if (kIsWeb) {
      return await _updateHabitWeb(habit);
    }
    final db = await database;
    // Ensure userId is set
    final map = habit.toMap();
    map['userId'] = userId;
    return await db.update(
      'habits',
      map,
      where: 'id = ? AND userId = ?',
      whereArgs: [habit.id, userId],
    );
  }

  Future<int> _updateHabitWeb(Habit habit) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    await _initWebDB();
    final userKey = 'habits_$userId';
    final habitsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> habits = json.decode(habitsJson);
    
    final index = habits.indexWhere((h) => h['id'] == habit.id && h['userId'] == userId);
    if (index == -1) return 0;
    
    final map = habit.toMap();
    map['userId'] = userId;
    habits[index] = map;
    await WebStorage.setString(userKey, json.encode(habits));
    return 1;
  }

  Future<int> deleteHabit(int id) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    if (kIsWeb) {
      return await _deleteHabitWeb(id);
    }
    final db = await database;
    // Delete completions first (CASCADE should handle this, but being explicit)
    await db.delete('completions', where: 'habitId = ? AND userId = ?', whereArgs: [id, userId]);
    return await db.delete('habits', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<int> _deleteHabitWeb(int id) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    await _initWebDB();
    
    // Delete habit
    final userHabitsKey = 'habits_$userId';
    final habitsJson = WebStorage.getString(userHabitsKey) ?? '[]';
    final List<dynamic> habits = json.decode(habitsJson);
    habits.removeWhere((h) => h['id'] == id && h['userId'] == userId);
    await WebStorage.setString(userHabitsKey, json.encode(habits));
    
    // Delete completions
    final userCompletionsKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userCompletionsKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    completions.removeWhere((c) => c['habitId'] == id && c['userId'] == userId);
    await WebStorage.setString(userCompletionsKey, json.encode(completions));
    
    return 1;
  }

  // Completion operations
  Future<int> insertCompletion(HabitCompletion completion) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    if (kIsWeb) {
      return await _insertCompletionWeb(completion);
    }
    final db = await database;
    final map = completion.toMap();
    map['userId'] = userId;
    return await db.insert('completions', map);
  }

  Future<int> _insertCompletionWeb(HabitCompletion completion) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    await _initWebDB();
    final userKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    
    // Generate new ID
    int newId = 1;
    if (completions.isNotEmpty) {
      final maxId = completions.map((c) => c['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
      newId = maxId + 1;
    }
    
    completion.id = newId;
    completion.userId = userId;
    completions.add(completion.toMap());
    
    await WebStorage.setString(userKey, json.encode(completions));
    return newId;
  }

  Future<bool> isHabitCompletedToday(int habitId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return false;
    }
    
    if (kIsWeb) {
      return await _isHabitCompletedTodayWeb(habitId);
    }
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'completions',
      where: 'habitId = ? AND userId = ? AND completedAt >= ? AND completedAt < ? AND isCompleted = 1',
      whereArgs: [
        habitId,
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );

    return result.isNotEmpty;
  }

  Future<String?> getTodayCompletionNote(int habitId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return null;
    }
    
    if (kIsWeb) {
      return await _getTodayCompletionNoteWeb(habitId);
    }
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'completions',
      where: 'habitId = ? AND userId = ? AND completedAt >= ? AND completedAt < ?',
      whereArgs: [
        habitId,
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );

    if (result.isEmpty) return null;
    final note = result.first['note'] as String?;
    return note?.isEmpty ?? true ? null : note;
  }

  Future<String?> _getTodayCompletionNoteWeb(int habitId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return null;
    }
    
    final completions = await _getCompletionsForHabitWeb(habitId);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      final todayCompletion = completions.firstWhere(
        (c) {
          final completedAt = DateTime.parse(c.completedAt.toIso8601String());
          return completedAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              completedAt.isBefore(endOfDay);
        },
      );
      
      return todayCompletion.note.isEmpty ? null : todayCompletion.note;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _isHabitCompletedTodayWeb(int habitId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return false;
    }
    
    final completions = await _getCompletionsForHabitWeb(habitId);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return completions.any((c) {
      final completedAt = DateTime.parse(c.completedAt.toIso8601String());
      return c.isCompleted &&
          completedAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          completedAt.isBefore(endOfDay);
    });
  }

  Future<void> toggleHabitCompletion(int habitId, bool isCompleted, {String note = ''}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    if (kIsWeb) {
      return await _toggleHabitCompletionWeb(habitId, isCompleted, note: note);
    }
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Check if completion exists for today
    final existing = await db.query(
      'completions',
      where: 'habitId = ? AND userId = ? AND completedAt >= ? AND completedAt < ?',
      whereArgs: [
        habitId,
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );

    if (existing.isNotEmpty) {
      // Update existing
      await db.update(
        'completions',
        {
          'isCompleted': isCompleted ? 1 : 0,
          'note': note,
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [existing.first['id'], userId],
      );
    } else {
      // Insert new
      await insertCompletion(HabitCompletion(
        habitId: habitId,
        userId: userId,
        completedAt: DateTime.now(),
        isCompleted: isCompleted,
        note: note,
      ));
    }
    // Update best streak after completion change
    if (isCompleted) {
      await updateBestStreak(habitId);
    }
  }

  Future<void> _toggleHabitCompletionWeb(int habitId, bool isCompleted, {String note = ''}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('No user selected. Please select a profile first.');
    }
    
    await _initWebDB();
    final userKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Find existing completion for today
    final existingIndex = completions.indexWhere((c) {
      final completedAt = DateTime.parse(c['completedAt'] as String);
      return c['habitId'] == habitId &&
          c['userId'] == userId &&
          completedAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          completedAt.isBefore(endOfDay);
    });
    
    if (existingIndex != -1) {
      // Update existing
      completions[existingIndex]['isCompleted'] = isCompleted ? 1 : 0;
      completions[existingIndex]['note'] = note;
    } else {
      // Insert new
      final newId = completions.isEmpty
          ? 1
          : (completions.map((c) => c['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      completions.add({
        'id': newId,
        'habitId': habitId,
        'userId': userId,
        'completedAt': DateTime.now().toIso8601String(),
        'isCompleted': isCompleted ? 1 : 0,
        'note': note,
      });
    }
    
    await WebStorage.setString(userKey, json.encode(completions));
    
    // Update best streak after completion change
    if (isCompleted) {
      await updateBestStreak(habitId);
    }
  }

  Future<List<HabitCompletion>> getCompletionsForHabit(
    int habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return [];
    }
    
    if (kIsWeb) {
      return await _getCompletionsForHabitWeb(habitId, startDate: startDate, endDate: endDate);
    }
    final db = await database;
    String whereClause = 'habitId = ? AND userId = ?';
    List<dynamic> whereArgs = [habitId, userId];

    if (startDate != null) {
      whereClause += ' AND completedAt >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND completedAt < ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'completions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completedAt DESC',
    );

    return result.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<List<HabitCompletion>> _getCompletionsForHabitWeb(
    int habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return [];
    }
    
    await _initWebDB();
    final userKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    
    var filtered = completions
        .where((c) => c['habitId'] == habitId && c['userId'] == userId)
        .map((map) => HabitCompletion.fromMap(Map<String, dynamic>.from(map)))
        .toList();
    
    if (startDate != null) {
      filtered = filtered.where((c) => c.completedAt.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((c) => c.completedAt.isBefore(endDate)).toList();
    }
    
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered;
  }

  // Calculate streak
  Future<int> getCurrentStreak(int habitId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return 0;
    }
    
    if (kIsWeb) {
      return await _getCurrentStreakWeb(habitId);
    }
    final db = await database;
    final today = DateTime.now();
    var currentDate = DateTime(today.year, today.month, today.day);
    int streak = 0;

    while (true) {
      final startOfDay = currentDate;
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.query(
        'completions',
        where: 'habitId = ? AND userId = ? AND completedAt >= ? AND completedAt < ? AND isCompleted = 1',
        whereArgs: [
          habitId,
          userId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
      );

      if (result.isEmpty) {
        // If today has no completion, check if streak should be 0
        if (currentDate == DateTime(today.year, today.month, today.day)) {
          break; // Today not completed, streak is 0
        }
        break; // Found a day without completion
      }

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> _getCurrentStreakWeb(int habitId) async {
    final completions = await _getCompletionsForHabitWeb(habitId);
    final today = DateTime.now();
    var currentDate = DateTime(today.year, today.month, today.day);
    int streak = 0;

    while (true) {
      final startOfDay = currentDate;
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final hasCompletion = completions.any((c) {
        final completedAt = DateTime.parse(c.completedAt.toIso8601String());
        return c.isCompleted &&
            completedAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            completedAt.isBefore(endOfDay);
      });

      if (!hasCompletion) {
        if (currentDate == DateTime(today.year, today.month, today.day)) {
          break; // Today not completed, streak is 0
        }
        break; // Found a day without completion
      }

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Calculate success rate (last 30 days)
  Future<double> getSuccessRate(int habitId) async {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 30));
    final startOfPeriod = DateTime(startDate.year, startDate.month, startDate.day);

    final completions = await getCompletionsForHabit(
      habitId,
      startDate: startOfPeriod,
    );

    final completedDays = completions
        .where((c) => c.isCompleted)
        .map((c) {
          final date = DateTime.parse(c.completedAt.toIso8601String());
          return DateTime(date.year, date.month, date.day);
        })
        .toSet()
        .length;

    final totalDays = today.difference(startOfPeriod).inDays;
    if (totalDays == 0) return 0.0;

    return (completedDays / totalDays) * 100;
  }

  // Update best streak if current streak is higher
  Future<void> updateBestStreak(int habitId) async {
    final currentStreak = await getCurrentStreak(habitId);
    final habit = await getHabit(habitId);
    if (habit != null && currentStreak > habit.bestStreak) {
      habit.bestStreak = currentStreak;
      await updateHabit(habit);
    }
  }

  // Get habits by category
  Future<List<Habit>> getHabitsByCategory(String category) async {
    final allHabits = await getAllHabits();
    return allHabits.where((h) => h.category == category).toList();
  }

  // Get all categories
  Future<List<String>> getAllCategories() async {
    final allHabits = await getAllHabits();
    final categories = allHabits.map((h) => h.category).toSet().toList();
    return categories..sort();
  }

  // Get today's completion count
  Future<int> getTodayCompletionsCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    if (kIsWeb) {
      return await _getTodayCompletionsCountWeb(startOfDay, endOfDay);
    }
    
    final db = await database;
    final result = await db.query(
      'completions',
      where: 'userId = ? AND completedAt >= ? AND completedAt < ? AND isCompleted = 1',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    
    // Count unique habitIds
    final uniqueHabits = result.map((r) => r['habitId'] as int).toSet();
    return uniqueHabits.length;
  }

  Future<int> _getTodayCompletionsCountWeb(DateTime startOfDay, DateTime endOfDay) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    
    await _initWebDB();
    final userKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    
    final todayCompletions = completions.where((c) {
      final completedAt = DateTime.parse(c['completedAt'] as String);
      return c['userId'] == userId &&
          c['isCompleted'] == 1 &&
          completedAt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          completedAt.isBefore(endOfDay);
    }).toList();
    
    final uniqueHabits = todayCompletions.map((c) => c['habitId'] as int).toSet();
    return uniqueHabits.length;
  }

  // Get weekly completions count
  Future<int> getWeeklyCompletionsCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    
    if (kIsWeb) {
      return await _getPeriodCompletionsCountWeb(startOfWeekDay, endOfWeek);
    }
    
    final db = await database;
    final result = await db.query(
      'completions',
      where: 'userId = ? AND completedAt >= ? AND completedAt < ? AND isCompleted = 1',
      whereArgs: [userId, startOfWeekDay.toIso8601String(), endOfWeek.toIso8601String()],
    );
    
    return result.length;
  }

  // Get monthly completions count
  Future<int> getMonthlyCompletionsCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 1);
    
    if (kIsWeb) {
      return await _getPeriodCompletionsCountWeb(startOfMonth, endOfMonth);
    }
    
    final db = await database;
    final result = await db.query(
      'completions',
      where: 'userId = ? AND completedAt >= ? AND completedAt < ? AND isCompleted = 1',
      whereArgs: [userId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
    
    return result.length;
  }

  Future<int> _getPeriodCompletionsCountWeb(DateTime startDate, DateTime endDate) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return 0;
    
    await _initWebDB();
    final userKey = 'completions_$userId';
    final completionsJson = WebStorage.getString(userKey) ?? '[]';
    final List<dynamic> completions = json.decode(completionsJson);
    
    final periodCompletions = completions.where((c) {
      final completedAt = DateTime.parse(c['completedAt'] as String);
      return c['userId'] == userId &&
          c['isCompleted'] == 1 &&
          completedAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          completedAt.isBefore(endDate);
    }).toList();
    
    return periodCompletions.length;
  }

  // Get longest current streak across all habits
  Future<int> getLongestCurrentStreak() async {
    final habits = await getAllHabits();
    if (habits.isEmpty) return 0;
    
    int longestStreak = 0;
    for (final habit in habits) {
      if (habit.id != null) {
        final streak = await getCurrentStreak(habit.id!);
        if (streak > longestStreak) {
          longestStreak = streak;
        }
      }
    }
    
    return longestStreak;
  }

  Future<void> close() async {
    if (!kIsWeb) {
      final db = await database;
      await db.close();
    }
  }
}

