import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';

class DailyTasksTab extends StatefulWidget {
  const DailyTasksTab({Key? key}) : super(key: key);

  @override
  State<DailyTasksTab> createState() => _DailyTasksTabState();
}

class _DailyTasksTabState extends State<DailyTasksTab> {
  UserHealthProfile? _userProfile;
  List<DailyTask> _tasks = [];
  bool _isLoading = true;
  bool _isGeneratingTasks = false;
  DateTime _lastGeneratedDate = DateTime(1970);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _userProfile = await DatabaseService().getUserHealthProfile('user_profile');
      await _loadTodaysTasks();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodaysTasks() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // Check if we have tasks for today
    final existingTasksData = await DatabaseService().getDailyTasks(todayKey);

    if (existingTasksData.isNotEmpty) {
      final tasks = existingTasksData.map((taskData) => DailyTask.fromJson(taskData)).toList();
      setState(() {
        _tasks = tasks;
        _lastGeneratedDate = today;
      });
    } else {
      // Generate new tasks for today
      await _generateTodaysTasks();
    }
  }

  Future<void> _generateTodaysTasks() async {
    if (_userProfile == null) return;

    setState(() {
      _isGeneratingTasks = true;
    });

    try {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';

      List<DailyTask> newTasks = [];

      // Generate basic health-related tasks
      newTasks.addAll(_generateBasicHealthTasks());

      // Try to enhance with Gemini AI if available
      if (GeminiService.isConfigured) {
        try {
          final aiTasksData = await GeminiService.generateDailyTasks(
            userProfile: _userProfile!,
            date: today,
          );
          // Convert the dynamic tasks to DailyTask objects
          final aiTasks = aiTasksData.map((taskData) => DailyTask.fromJson(taskData)).toList();
          newTasks.addAll(aiTasks);
        } catch (e) {
          debugPrint('Error with Gemini task generation: $e');
        }
      }

      // Save tasks to database
      await DatabaseService().saveDailyTasks(todayKey, newTasks);

      setState(() {
        _tasks = newTasks;
        _lastGeneratedDate = today;
      });
    } catch (e) {
      debugPrint('Error generating tasks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to generate daily tasks'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingTasks = false;
      });
    }
  }

  List<DailyTask> _generateBasicHealthTasks() {
    final tasks = <DailyTask>[];
    final now = DateTime.now();

    // Add air quality check task
    tasks.add(DailyTask(
      id: 'check_air_quality_${now.millisecondsSinceEpoch}',
      title: 'Check Air Quality',
      description: 'Check the air quality at your pinned locations before planning outdoor activities',
      category: TaskCategory.health,
      isCompleted: false,
      createdAt: now,
    ));

    // Add health-specific tasks based on user profile
    if (_userProfile?.conditions.contains(HealthCondition.asthma) == true) {
      tasks.add(DailyTask(
        id: 'inhaler_check_${now.millisecondsSinceEpoch}',
        title: 'Check Inhaler',
        description: 'Make sure your inhaler is accessible and not expired',
        category: TaskCategory.health,
        isCompleted: false,
        createdAt: now,
      ));
    }

    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.athlete) == true) {
      tasks.add(DailyTask(
        id: 'plan_workout_${now.millisecondsSinceEpoch}',
        title: 'Plan Workout',
        description: 'Choose indoor or outdoor exercise based on air quality conditions',
        category: TaskCategory.fitness,
        isCompleted: false,
        createdAt: now,
      ));
    }

    // Add general wellness tasks
    tasks.add(DailyTask(
      id: 'hydration_${now.millisecondsSinceEpoch}',
      title: 'Stay Hydrated',
      description: 'Drink at least 8 glasses of water throughout the day',
      category: TaskCategory.wellness,
      isCompleted: false,
      createdAt: now,
    ));

    return tasks;
  }

  Future<void> _toggleTaskCompletion(DailyTask task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);

    if (taskIndex != -1) {
      setState(() {
        _tasks[taskIndex] = updatedTask;
      });

      // Update in database
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      await DatabaseService().saveDailyTasks(todayKey, _tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Tasks'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateTodaysTasks,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isGeneratingTasks
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating your daily tasks...'),
                  ],
                ),
              )
            : _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks for today',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the refresh button to generate new tasks',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDateHeader(),
                      const SizedBox(height: 16),
                      _buildCompletionProgress(),
                      const SizedBox(height: 24),
                      ..._buildTasksByCategory(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);
    final monthName = _getMonthName(today.month);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, $monthName ${today.day}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your personalized daily tasks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionProgress() {
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedTasks/$totalTasks completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTasksByCategory() {
    final categories = TaskCategory.values;
    final widgets = <Widget>[];

    for (final category in categories) {
      final categoryTasks = _tasks.where((task) => task.category == category).toList();
      if (categoryTasks.isNotEmpty) {
        widgets.add(_buildCategorySection(category, categoryTasks));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  Widget _buildCategorySection(TaskCategory category, List<DailyTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(DailyTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskCompletion(task),
          activeColor: Theme.of(context).colorScheme.primary,
          checkColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                : null,
          ),
        ),
        subtitle: Text(
          task.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: task.isCompleted
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: TaskCategory.values.firstWhere((c) => c.name == json['category']),
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum TaskCategory {
  health,
  fitness,
  wellness,
  safety,
  planning
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.fitness:
        return 'Fitness';
      case TaskCategory.wellness:
        return 'Wellness';
      case TaskCategory.safety:
        return 'Safety';
      case TaskCategory.planning:
        return 'Planning';
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.health:
        return '🏥';
      case TaskCategory.fitness:
        return '💪';
      case TaskCategory.wellness:
        return '🧘';
      case TaskCategory.safety:
        return '🛡️';
      case TaskCategory.planning:
        return '📋';
    }
  }
}