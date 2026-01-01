import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../models/habit_model.dart';
import '../services/db_service.dart';
import '../services/theme_service.dart';
import '../services/export_service.dart';
import '../services/user_service.dart';
import '../widgets/habit_tile.dart';
import '../widgets/progress_dashboard.dart';
import 'add_habit_screen.dart';
import 'habit_details_screen.dart';
import 'achievements_screen.dart';
import 'profile_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(ThemeMode)? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  List<Habit> _filteredHabits = [];
  bool _isLoading = true;
  String? _selectedCategory;
  int _dashboardRefreshKey = 0;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _startGreetingTimer();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _startGreetingTimer() {
    // Calculate time until next boundary (12:00 PM or 5:00 PM)
    final now = DateTime.now();
    final nextBoundary = _getNextGreetingBoundary(now);
    final durationUntilBoundary = nextBoundary.difference(now);
    
    // Set timer to update at the next boundary
    _greetingTimer = Timer(durationUntilBoundary, () {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update greeting
        });
        // Schedule next update
        _startGreetingTimer();
      }
    });
  }

  DateTime _getNextGreetingBoundary(DateTime now) {
    final hour = now.hour;
    DateTime nextBoundary;
    
    if (hour < 12) {
      // Next boundary is 12:00 PM (noon)
      nextBoundary = DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else if (hour < 17) {
      // Next boundary is 5:00 PM
      nextBoundary = DateTime(now.year, now.month, now.day, 17, 0, 0);
    } else {
      // Next boundary is 12:00 AM (midnight) next day
      nextBoundary = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    }
    
    return nextBoundary;
  }

  void _applyFilter() {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      _filteredHabits = _habits;
    } else {
      _filteredHabits = _habits.where((h) => h.category == _selectedCategory).toList();
    }
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final habits = await DatabaseService.instance.getAllHabits();
      
      if (mounted) {
        setState(() {
          _habits = habits;
          _applyFilter();
          _isLoading = false;
          _dashboardRefreshKey++; // Trigger dashboard refresh
        });
      }
    } catch (e) {
      // Handle any errors that occur during loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading habits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && habit.id != null) {
      await DatabaseService.instance.deleteHabit(habit.id!);
      _loadHabits();
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your habits and completion history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // This would require implementing a clearAll method in DatabaseService
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            )
          : _habits.isEmpty
              ? CustomScrollView(
                  slivers: [
                    // Modern App Bar
                    SliverAppBar(
                      expandedHeight: 140,
                      floating: false,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            bottom: 16,
                            right: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.settings_outlined,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SettingsScreen(
                                          onClearAllData: _clearAllData,
                                          onThemeChanged: widget.onThemeChanged,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Empty State
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _loadHabits,
                  color: const Color(0xFF6C63FF),
                  child: CustomScrollView(
                    slivers: [
                      // Modern App Bar
                      SliverAppBar(
                        expandedHeight: 140,
                        floating: false,
                        pinned: true,
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: EdgeInsets.zero,
                          title: Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              bottom: 16,
                              right: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.settings_outlined,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SettingsScreen(
                                            onClearAllData: _clearAllData,
                                            onThemeChanged: widget.onThemeChanged,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Progress Dashboard
                      SliverToBoxAdapter(
                        child: ProgressDashboard(
                          habits: _habits,
                          refreshKey: ValueKey(_dashboardRefreshKey),
                        ),
                      ),
                      // Category Filter
                      SliverToBoxAdapter(
                        child: _buildCategoryFilter(),
                      ),
                      // Habits List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = _filteredHabits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: Key('habit_${habit.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  onDismissed: (_) => _deleteHabit(habit),
                                  child: HabitTile(
                                    habit: habit,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HabitDetailsScreen(
                                            habit: habit,
                                          ),
                                        ),
                                      ).then((_) => _loadHabits());
                                    },
                                    onDeleted: _loadHabits,
                                    onDelete: () => _deleteHabit(habit),
                                    onCompleted: () {
                                      // Refresh dashboard when habit is completed
                                      setState(() {
                                        _dashboardRefreshKey++;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredHabits.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _habits.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                  );
                  if (result == true) {
                    _loadHabits();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Add Habit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 80,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first habit and begin building\na better version of yourself',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                );
                if (result == true) {
                  _loadHabits();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Habit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildCategoryFilter() {
    if (_habits.isEmpty) return const SizedBox.shrink();
    
    final categories = ['All', ..._habits.map((h) => h.category).toSet().toList()..sort()];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category || (_selectedCategory == null && category == 'All');
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                  _applyFilter();
                });
              },
              selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(
                color: isSelected 
                    ? const Color(0xFF6C63FF) 
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Settings Screen (simple version)
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onClearAllData;
  final void Function(ThemeMode)? onThemeChanged;

  const SettingsScreen({super.key, this.onClearAllData, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = ThemeService.instance.getThemeMode();
    setState(() {
      _currentThemeMode = mode;
    });
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() {
      _currentThemeMode = mode;
    });
    await ThemeService.instance.setThemeMode(mode);
    widget.onThemeChanged?.call(mode);
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final csvData = await ExportService.instance.generateCSV();
      final jsonData = await ExportService.instance.generateJSON();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show export options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Data'),
            content: const Text('Choose export format:'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveFile(context, csvData, 'habits_export.csv', 'text/csv');
                },
                child: const Text('CSV'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveFile(context, jsonData, 'habits_export.json', 'application/json');
                },
                child: const Text('JSON'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _saveFile(BuildContext context, String content, String filename, String mimeType) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, copy to clipboard and show message
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data copied to clipboard! You can paste it into a file.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // For desktop/web, try to save file
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to: ${file.path}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FutureBuilder(
            future: UserService.instance.getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    child: Icon(
                      _getAvatarIcon(user.avatar ?? 'person'),
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSelectionScreen(onThemeChanged: widget.onThemeChanged),
                      ),
                    );
                    if (result == true && mounted) {
                      // Reload the home screen with new user
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(onThemeChanged: widget.onThemeChanged),
                        ),
                      );
                    }
                  },
                );
              }
              return ListTile(
                leading: const Icon(Icons.person),
                title: const Text('No profile selected'),
                subtitle: const Text('Tap to select a profile'),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSelectionScreen(onThemeChanged: widget.onThemeChanged),
                    ),
                  );
                  if (result == true && mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(onThemeChanged: widget.onThemeChanged),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const Divider(),
          // Theme Settings
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: _currentThemeMode,
            onChanged: (value) => _changeTheme(value!),
            secondary: const Icon(Icons.light_mode),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: _currentThemeMode,
            onChanged: (value) => _changeTheme(value!),
            secondary: const Icon(Icons.dark_mode),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: _currentThemeMode,
            onChanged: (value) => _changeTheme(value!),
            secondary: const Icon(Icons.brightness_auto),
          ),
          const Divider(),
          // About
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Achievements'),
            subtitle: const Text('View your progress and milestones'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('HabitMate v1.0.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About HabitMate'),
                  content: const Text(
                    'A simple and effective habit tracking app to help you build better habits, one day at a time.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          // Data Management
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Export your habits and completions'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all habits and completions'),
            onTap: widget.onClearAllData,
          ),
        ],
      ),
    );
  }

  IconData _getAvatarIcon(String avatar) {
    switch (avatar) {
      case 'person':
        return Icons.person;
      case 'face':
        return Icons.face;
      case 'child_care':
        return Icons.child_care;
      case 'sports':
        return Icons.sports;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      default:
        return Icons.person;
    }
  }
}

