import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  List<Achievement> _allAchievements = [];
  List<Achievement> _unlockedAchievements = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadAchievements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    final all = AchievementService.instance.getAllAchievements();
    final unlocked = await AchievementService.instance.checkAchievements();
    
    // Merge to show unlocked status
    final merged = all.map((achievement) {
      final unlockedAchievement = unlocked.firstWhere(
        (a) => a.id == achievement.id,
        orElse: () => achievement,
      );
      return unlockedAchievement;
    }).toList();

    setState(() {
      _allAchievements = merged;
      _unlockedAchievements = unlocked;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF6C63FF),
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: RefreshIndicator(
                    onRefresh: _loadAchievements,
                    color: const Color(0xFF6C63FF),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                    // Enhanced Header
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF),
                                const Color(0xFF6C63FF).withValues(alpha: 0.85),
                                const Color(0xFF6C63FF).withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
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
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 56),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: Text(
                                        '${_unlockedAchievements.length} / ${_allAchievements.length}',
                                        style: const TextStyle(
                                          fontSize: 52,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Achievements Unlocked',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Achievements List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final achievement = _allAchievements[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildAchievementCard(achievement, isDark),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _allAchievements.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDark) {
    final primaryColor = const Color(0xFF6C63FF);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achievement.unlocked
              ? primaryColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
          width: achievement.unlocked ? 1.5 : 1,
        ),
        boxShadow: achievement.unlocked
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: achievement.unlocked
                        ? LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.2),
                              primaryColor.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: achievement.unlocked
                        ? null
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(18),
                    border: achievement.unlocked
                        ? Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: achievement.unlocked
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: achievement.unlocked ? 1.0 : 0.5,
                      child: Text(
                        achievement.icon,
                        style: const TextStyle(
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: achievement.unlocked
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: achievement.unlocked
                              ? (isDark ? Colors.white70 : Colors.black54)
                              : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: achievement.unlocked
                        ? primaryColor.withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: achievement.unlocked
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: primaryColor,
                          size: 28,
                        )
                      : Icon(
                          Icons.lock_outline_rounded,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

