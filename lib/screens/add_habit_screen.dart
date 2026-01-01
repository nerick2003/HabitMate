import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/habit_model.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // For editing existing habit

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _frequency = 'daily';
  String _selectedColor = '#6C63FF';
  String _selectedIcon = 'fitness_center';
  String _selectedCategory = 'General';
  List<String> _reminderTimes = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'General',
    'Health',
    'Fitness',
    'Work',
    'Personal',
    'Learning',
    'Social',
    'Finance',
    'Creative',
  ];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Purple', 'value': '#6C63FF'},
    {'name': 'Blue', 'value': '#2196F3'},
    {'name': 'Green', 'value': '#4CAF50'},
    {'name': 'Orange', 'value': '#FF9800'},
    {'name': 'Red', 'value': '#F44336'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'fitness_center', 'icon': Icons.fitness_center},
    {'name': 'book', 'icon': Icons.book},
    {'name': 'water_drop', 'icon': Icons.water_drop},
    {'name': 'local_dining', 'icon': Icons.local_dining},
    {'name': 'bedtime', 'icon': Icons.bedtime},
    {'name': 'self_improvement', 'icon': Icons.self_improvement},
    {'name': 'sports_esports', 'icon': Icons.sports_esports},
    {'name': 'music_note', 'icon': Icons.music_note},
    {'name': 'code', 'icon': Icons.code},
    {'name': 'brush', 'icon': Icons.brush},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description;
      _frequency = widget.habit!.frequency;
      _selectedColor = widget.habit!.color;
      _selectedIcon = widget.habit!.icon;
      _selectedCategory = widget.habit!.category;
      _reminderTimes = List.from(widget.habit!.reminderTimes);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final currentUser = await UserService.instance.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a profile first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final habit = Habit(
        id: widget.habit?.id,
        userId: currentUser.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        frequency: _frequency,
        reminderTimes: _reminderTimes,
        color: _selectedColor,
        icon: _selectedIcon,
        category: _selectedCategory,
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
      );

      if (habit.id == null) {
        // New habit
        final id = await DatabaseService.instance.insertHabit(habit);
        habit.id = id;
      } else {
        // Update existing
        await DatabaseService.instance.updateHabit(habit);
      }

      // Schedule notifications (don't fail save if notifications fail)
      if (_reminderTimes.isNotEmpty) {
        try {
          await NotificationService.instance.scheduleHabitReminders(habit);
        } catch (e) {
          // Log but don't prevent save if notifications fail
          print('Failed to schedule notifications: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save habit: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _addReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!_reminderTimes.contains(timeString)) {
        setState(() {
          _reminderTimes.add(timeString);
          _reminderTimes.sort();
        });
      }
    }
  }

  void _removeReminderTime(String time) {
    setState(() {
      _reminderTimes.remove(time);
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
    final color = _getColorFromHex(_selectedColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        title: Text(
          widget.habit == null ? 'New Habit' : 'Edit Habit',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    const SizedBox(height: 8),
                    // Enhanced Preview Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.85),
                            color.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _icons.firstWhere((i) => i['name'] == _selectedIcon)['icon'],
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'Habit Name'
                                      : _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _descriptionController.text.isEmpty
                                      ? 'Description'
                                      : _descriptionController.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Icon Selection
                    _buildSectionHeader('Choose Icon', Icons.palette_outlined),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: _icons.asMap().entries.map((entry) {
                        final index = entry.key;
                        final icon = entry.value;
                        final isSelected = icon['name'] == _selectedIcon;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 30)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: _ModernIconButton(
                                  icon: icon['icon'] as IconData,
                                  isSelected: isSelected,
                                  color: color,
                                  onTap: () => setState(() => _selectedIcon = icon['name']),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Color Selection
                    _buildSectionHeader('Choose Color', Icons.color_lens_outlined),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      children: _colors.map((colorData) {
                        final isSelected = colorData['value'] == _selectedColor;
                        final colorValue = _getColorFromHex(colorData['value']);
                        return _ModernColorButton(
                          color: colorValue,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedColor = colorData['value']),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Name Field
                    _buildSectionHeader('Details', Icons.edit_note_rounded),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Habit Name *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          hintText: 'e.g., Drink Water, Exercise',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a habit name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Enhanced Description Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          hintText: 'Add a note about this habit',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Category Selection
                    _buildSectionHeader('Category', Icons.category_outlined),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((category) {
                        final isSelected = category == _selectedCategory;
                        return _ModernCategoryChip(
                          label: category,
                          isSelected: isSelected,
                          color: color,
                          onTap: () => setState(() => _selectedCategory = category),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Frequency Selection
                    _buildSectionHeader('Frequency', Icons.repeat_rounded),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'daily',
                            label: Text('Daily'),
                            icon: Icon(Icons.calendar_today, size: 20),
                          ),
                          ButtonSegment(
                            value: 'weekly',
                            label: Text('Weekly'),
                            icon: Icon(Icons.date_range, size: 20),
                          ),
                        ],
                        selected: {_frequency},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _frequency = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          backgroundColor: Colors.transparent,
                          selectedBackgroundColor: color.withValues(alpha: 0.2),
                          selectedForegroundColor: color,
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Enhanced Reminders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Reminders', Icons.notifications_outlined),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _addReminderTime,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Add Time',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_reminderTimes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'No reminders set',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._reminderTimes.map((time) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _removeReminderTime(time),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Enhanced Save Button at bottom
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saveHabit,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Save Habit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom safe area padding
              SafeArea(
                top: false,
                child: Container(
                  height: 8,
                  color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorFromHex(_selectedColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: _getColorFromHex(_selectedColor),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// Modern Icon Button Widget
class _ModernIconButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModernIconButton({
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<_ModernIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.2)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            widget.icon,
            color: widget.isSelected ? widget.color : (isDark ? Colors.white70 : Colors.grey[700]),
            size: 30,
          ),
        ),
      ),
    );
  }
}

// Modern Color Button Widget
class _ModernColorButton extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModernColorButton> createState() => _ModernColorButtonState();
}

class _ModernColorButtonState extends State<_ModernColorButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              width: widget.isSelected ? 4.5 : 0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.isSelected
              ? const Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                    weight: 3,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// Modern Category Chip Widget
class _ModernCategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModernCategoryChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModernCategoryChip> createState() => _ModernCategoryChipState();
}

class _ModernCategoryChipState extends State<_ModernCategoryChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.2)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300),
              width: widget.isSelected ? 2 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: widget.color,
                  size: 18,
                )
              else
                const SizedBox(width: 0),
              if (widget.isSelected) const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? widget.color
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

