import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/db_service.dart';
import 'note_dialog.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final VoidCallback? onDelete;
  final VoidCallback? onCompleted; // Callback when habit is completed/uncompleted

  const HabitTile({
    super.key,
    required this.habit,
    this.onTap,
    this.onDeleted,
    this.onDelete,
    this.onCompleted,
  });

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  bool _isCompleted = false;
  bool _isLoading = false;
  int _streak = 0;
  String? _todayNote;

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
    _loadStreak();
    _loadTodayNote();
  }

  Future<void> _loadCompletionStatus() async {
    final isCompleted = await DatabaseService.instance
        .isHabitCompletedToday(widget.habit.id!);
    if (mounted) {
      setState(() {
        _isCompleted = isCompleted;
      });
    }
  }

  Future<void> _loadStreak() async {
    if (widget.habit.id == null) return;
    final streak = await DatabaseService.instance
        .getCurrentStreak(widget.habit.id!);
    if (mounted) {
      setState(() {
        _streak = streak;
      });
    }
  }

  Future<void> _loadTodayNote() async {
    if (widget.habit.id == null) return;
    final note = await DatabaseService.instance.getTodayCompletionNote(widget.habit.id!);
    if (mounted) {
      setState(() {
        _todayNote = note;
      });
    }
  }

  Future<void> _toggleCompletion(bool? value) async {
    if (widget.habit.id == null || value == null) return;

    String? note;
    if (value) {
      // Show note dialog when completing
      note = await showDialog<String>(
        context: context,
        builder: (context) => NoteDialog(
          initialNote: _todayNote,
          habitName: widget.habit.name,
        ),
      );
      // If user cancels, don't complete
      if (note == null && _todayNote == null) {
        return;
      }
      note ??= _todayNote ?? '';
    }

    setState(() {
      _isLoading = true;
    });

    await DatabaseService.instance.toggleHabitCompletion(
      widget.habit.id!,
      value,
      note: note ?? '',
    );

    setState(() {
      _isCompleted = value;
      _isLoading = false;
    });

    // Reload streak and note after completion
    await _loadStreak();
    await _loadTodayNote();
    
    // Notify parent that habit was completed/uncompleted
    widget.onCompleted?.call();
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
    final color = _getColorFromHex(widget.habit.color);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(widget.habit.icon),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_streak > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_streak',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.habit.frequency == 'weekly')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Weekly',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        if (_todayNote != null && _todayNote!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.note,
                            size: 14,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button and Checkbox
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete button
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 22,
                      ),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete habit',
                    ),
                  if (widget.onDelete != null) const SizedBox(width: 12),
                  // Checkbox with modern design
                  if (_isLoading)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                      ),
                    )
                  else
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _isCompleted,
                        onChanged: _toggleCompletion,
                        activeColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}

