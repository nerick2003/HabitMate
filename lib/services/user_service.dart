import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserService {
  static final UserService instance = UserService._init();
  static const String _usersKey = 'users';
  static const String _currentUserIdKey = 'current_user_id';

  UserService._init();

  // Get all users
  Future<List<User>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null || usersJson.isEmpty) {
      return [];
    }
    final List<dynamic> usersList = json.decode(usersJson);
    return usersList.map((map) => User.fromMap(Map<String, dynamic>.from(map))).toList();
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt(_currentUserIdKey);
    if (currentUserId == null) return null;
    
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.id == currentUserId);
    } catch (e) {
      return null;
    }
  }

  // Set current user
  Future<void> setCurrentUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentUserIdKey, userId);
  }

  // Create a new user
  Future<int> createUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    
    // Generate new ID
    int newId = 1;
    if (users.isNotEmpty) {
      final maxId = users.map((u) => u.id ?? 0).reduce((a, b) => a > b ? a : b);
      newId = maxId + 1;
    }
    
    user.id = newId;
    users.add(user);
    
    await prefs.setString(_usersKey, json.encode(users.map((u) => u.toMap()).toList()));
    return newId;
  }

  // Update user
  Future<void> updateUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    
    final index = users.indexWhere((u) => u.id == user.id);
    if (index == -1) return;
    
    users[index] = user;
    await prefs.setString(_usersKey, json.encode(users.map((u) => u.toMap()).toList()));
  }

  // Delete user
  Future<void> deleteUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    users.removeWhere((u) => u.id == userId);
    
    await prefs.setString(_usersKey, json.encode(users.map((u) => u.toMap()).toList()));
    
    // If deleted user was current, clear current user
    final currentUserId = prefs.getInt(_currentUserIdKey);
    if (currentUserId == userId) {
      await prefs.remove(_currentUserIdKey);
    }
  }

  // Get user by ID
  Future<User?> getUserById(int userId) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }
}

