import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/color_extension.dart';

/// Daily Tasks Tab - Main screen for displaying and managing daily health tasks
/// This widget provides a comprehensive task management system with AI integration
class DailyTasksTab extends StatefulWidget {
  const DailyTasksTab({Key? key}) : super(key: key);

  @override
  State<DailyTasksTab> createState() => _DailyTasksTabState();
}

class _DailyTasksTabState extends State<DailyTasksTab> {
  // === STATE VARIABLES ===

  /// User's health profile containing conditions, age, lifestyle factors
  UserHealthProfile? _userProfile;

  /// List of all daily tasks for today
  List<DailyTask> _tasks = [];

  /// Loading state for initial data fetch
  bool _isLoading = true;

  /// Loading state specifically for AI task generation
  bool _isGeneratingTasks = false;

  /// Timestamp of when tasks were last generated (for display purposes)
  DateTime _lastGeneratedDate = DateTime(1970);

  /// Current difficulty/progress level (1-10 scale)
  /// Affects task complexity and AI recommendations
  int _currentProgressLevel = 1; // 1-10 progress levels

  /// AI-generated guidance text for the day
  String _aiGuidance = '';

  // === LIFECYCLE METHODS ===

  @override
  void initState() {
    super.initState();
    // Load initial data when the widget is first created
    _loadData();
  }

  /// Main data loading function - loads user profile and today's tasks
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user's health profile from local database
      _userProfile =
          await DatabaseService().getUserHealthProfile('user_profile');

      // Load or generate today's tasks
      await _loadTodaysTasks();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      // Always stop loading spinner, even if there's an error
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
      final tasks = existingTasksData
          .map((taskData) => DailyTask.fromJson(taskData))
          .toList();
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
          // Generate AI tasks based on current progress level

          final aiTasksData = await GeminiService.generateDailyTasks(
            userProfile: _userProfile!,
            date: today,
            progressLevel: _currentProgressLevel,
          );

          // Convert the dynamic tasks to DailyTask objects
          final aiTasks = aiTasksData.map((taskData) => DailyTask.fromJson(taskData)).toList();
          newTasks.addAll(aiTasks);

          // Generate AI guidance for the day
          _aiGuidance = await GeminiService.generateTaskPrompt(
            userProfile: _userProfile!,
            taskType: 'Daily Health Management',
            progressLevel: _currentProgressLevel,
          );
        } catch (e) {
          print('Error with Gemini task generation: $e');
        }
      }

      // Save tasks to database
      await DatabaseService().saveDailyTasks(todayKey, newTasks);

      setState(() {
        _tasks = newTasks;
        _lastGeneratedDate = today;
      });
    } catch (e) {
      print('Error generating tasks: $e');
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

    // Core health tasks (always included)
    final basicTasks = [
      {
        'title': 'Check Air Quality',
        'description':
            'Check the air quality at your pinned locations before planning outdoor activities',
        'category': TaskCategory.environmental,
      },
      {
        'title': 'Stay Hydrated',
        'description': 'Drink at least 8 glasses of water throughout the day',
        'category': TaskCategory.wellness,
      },
      {
        'title': 'Take Vitamins',
        'description': 'Take your daily vitamins and supplements if prescribed',
        'category': TaskCategory.nutrition,
      },
      {
        'title': 'Practice Deep Breathing',
        'description':
            '5-minute breathing exercise to reduce stress and improve oxygen flow',
        'category': TaskCategory.mental,
      },
      {
        'title': 'Review Health Goals',
        'description':
            'Check progress on your personal health objectives for the week',
        'category': TaskCategory.planning,
      },
      {
        'title': 'Morning Outdoor Walk',
        'description':
            'Take a 15-minute walk outside when air quality is good (AQI < 50)',
        'category': TaskCategory.fitness,
      },
      {
        'title': 'Air Purifier Check',
        'description':
            'Ensure your air purifier filter is clean and the device is running properly',
        'category': TaskCategory.environmental,
      },
      {
        'title': 'Practice Gratitude',
        'description':
            'Write down three things you are grateful for today in a journal or note app',
        'category': TaskCategory.mental,
      },
      {
        'title': 'Anti-Inflammatory Meal',
        'description':
            'Prepare a meal with anti-inflammatory foods like berries, leafy greens, or fatty fish',
        'category': TaskCategory.nutrition,
      },
      {
        'title': 'Track Symptoms',
        'description':
            'Log any respiratory symptoms and correlate with environmental conditions',
        'category': TaskCategory.health,
      },
      {
        'title': 'Ventilate Your Home',
        'description':
            'Open windows for 15 minutes when outdoor air quality is good',
        'category': TaskCategory.environmental,
      },
      {
        'title': 'Mindful Meditation',
        'description':
            '10-minute meditation focusing on breath and body awareness',
        'category': TaskCategory.wellness,
      },
      {
        'title': 'Social Connection',
        'description':
            'Call or meet a friend or family member to boost mental wellbeing',
        'category': TaskCategory.social,
      },
      {
        'title': 'Learn About Allergens',
        'description': 'Read an article about seasonal allergens in your area',
        'category': TaskCategory.education,
      },
      {
        'title': 'Check Indoor Air Quality',
        'description':
            'Assess your home for dust, mold, or other indoor air pollutants',
        'category': TaskCategory.safety,
      },
    ];

    // Add basic tasks
    for (int i = 0; i < basicTasks.length; i++) {
      final taskData = basicTasks[i];
      tasks.add(DailyTask(
        id: '${taskData['title'].toString().toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}_$i',
        title: taskData['title'] as String,
        description: taskData['description'] as String,
        category: taskData['category'] as TaskCategory,
        isCompleted: false,
        createdAt: now,
        progressLevel: _currentProgressLevel,
      ));
    }

    // Add health-specific tasks based on user profile
    if (_userProfile?.conditions.contains(HealthCondition.asthma) == true) {
      tasks.add(DailyTask(
        id: 'inhaler_check_${now.millisecondsSinceEpoch}',
        title: 'Check Inhaler',
        description: 'Make sure your inhaler is accessible and not expired',
        category: TaskCategory.health,
        isCompleted: false,
        createdAt: now,
        progressLevel: _currentProgressLevel,
      ));
    }

    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.athlete) == true) {
      final workoutDescription = _getProgressBasedWorkoutDescription();
      tasks.add(DailyTask(
        id: 'plan_workout_${now.millisecondsSinceEpoch}',
        title: 'Plan Workout',
        description: workoutDescription,
        category: TaskCategory.fitness,
        isCompleted: false,
        createdAt: now,
        progressLevel: _currentProgressLevel,
      ));
    }

    // Add additional tasks to reach closer to 10 if AI doesn't generate enough
    final additionalTasks = [
      {
        'title': 'Stretch & Move',
        'description': 'Take breaks to stretch and move around every hour',
        'category': TaskCategory.fitness,
      },
      {
        'title': 'Connect with Someone',
        'description': 'Reach out to a friend or family member today',
        'category': TaskCategory.social,
      },
      {
        'title': 'Learn Something New',
        'description':
            'Read an article or watch a video about health and wellness',
        'category': TaskCategory.education,
      },
      {
        'title': 'Check Safety Measures',
        'description': 'Ensure your home environment is safe and healthy',
        'category': TaskCategory.safety,
      },
    ];

    // Add additional tasks if we don't have enough
    int additionalCount = 0;
    while (tasks.length < 6 && additionalCount < additionalTasks.length) {
      final taskData = additionalTasks[additionalCount];
      tasks.add(DailyTask(
        id: '${taskData['title'].toString().toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}_${tasks.length}',
        title: taskData['title'] as String,
        description: taskData['description'] as String,
        category: taskData['category'] as TaskCategory,
        isCompleted: false,
        createdAt: now,
        progressLevel: _currentProgressLevel,
      ));
      additionalCount++;
    }

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
        title: Row(
          children: [
            const Text('📋'),
            const SizedBox(width: 8),
            const Text('Daily Tasks'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_tasks.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate AI Tasks',
            onPressed: _generateTodaysTasks,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tasks',
            onPressed: _loadData,
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('📝', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks for today',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the ✨ button to generate AI-powered tasks',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _generateTodaysTasks,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Tasks'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDateHeader(),
                      const SizedBox(height: 16),
                      _buildProgressLevelSelector(),
                      const SizedBox(height: 16),
                      _buildCompletionProgress(),
                      const SizedBox(height: 16),
                      _buildAIGuidanceCard(),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$dayName, $monthName ${today.day}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📅',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _lastGeneratedDate.year > 1970
                            ? Icons.auto_awesome
                            : Icons.task_alt,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _lastGeneratedDate.year > 1970
                              ? 'Tasks generated ${_formatLastGenerated()}'
                              : 'Your personalized daily tasks',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      progress >= 1.0
                          ? '🎉'
                          : progress >= 0.5
                              ? '⭐'
                              : '💪',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCompletionColor(progress).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getCompletionColor(progress)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCompletionIcon(progress),
                        color: _getCompletionColor(progress),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedTasks/$totalTasks',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: _getCompletionColor(progress),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
      final categoryTasks =
          _tasks.where((task) => task.category == category).toList();
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
        Container(
          margin: const EdgeInsets.only(left: 16, bottom: 12, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: category.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.materialIcon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: category.color.withValues(alpha: 0.9),
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: category.color,
                        fontWeight: FontWeight.bold,
                      ),
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
    final progressColor = _getProgressColor(task.progressLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskCompletion(task),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)
                          : null,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: progressColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                'L${task.progressLevel}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.isCompleted
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                  ),
            ),
            if (task.aiPrompt != null && task.aiPrompt!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: task.aiPrompt != null && task.aiPrompt!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showTaskGuidance(task),
              )
            : null,
      ),
    );
  }

  Color _getProgressColor(int level) {
    if (level <= 2) return Colors.green;
    if (level <= 4) return Colors.blue;
    if (level <= 6) return Colors.orange;
    if (level <= 8) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getProgressIcon(int level) {
    if (level <= 2) return Icons.radio_button_unchecked;
    if (level <= 4) return Icons.adjust;
    if (level <= 6) return Icons.lens;
    if (level <= 8) return Icons.circle;
    return Icons.stars;
  }

  Color _getCompletionColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  IconData _getCompletionIcon(double progress) {
    if (progress >= 1.0) return Icons.check_circle;
    if (progress >= 0.7) return Icons.check_circle_outline;
    if (progress >= 0.4) return Icons.radio_button_checked;
    return Icons.radio_button_unchecked;
  }

  Future<void> _showTaskGuidance(DailyTask task) async {
    if (!GeminiService.isConfigured || _userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(task.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Level: ${task.progressLevel}/10',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _getProgressColor(task.progressLevel),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: GeminiService.generateTaskPrompt(
                userProfile: _userProfile!,
                taskType: task.title,
                progressLevel: task.progressLevel,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error loading guidance: ${snapshot.error}');
                }
                return Text(snapshot.data ?? 'No guidance available');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatLastGenerated() {
    final now = DateTime.now();
    final difference = now.difference(_lastGeneratedDate);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getProgressBasedWorkoutDescription() {
    switch (_currentProgressLevel) {
      case 1:
      case 2:
        return 'Light stretches or 10-minute walk based on air quality conditions';
      case 3:
      case 4:
        return '20-30 minute moderate exercise session based on air quality conditions';
      case 5:
      case 6:
        return 'Plan structured workout routine considering air quality and fitness goals';
      case 7:
      case 8:
        return 'Intensive training session with air quality monitoring and performance tracking';
      case 9:
      case 10:
        return 'Advanced athletic training with comprehensive environmental assessment';
      default:
        return 'Choose indoor or outdoor exercise based on air quality conditions';
    }
  }

  Future<void> _adjustProgressLevel(int newLevel) async {
    if (newLevel >= 1 && newLevel <= 10 && newLevel != _currentProgressLevel) {
      setState(() {
        _currentProgressLevel = newLevel;
      });

      // Regenerate tasks for new progress level
      await _generateTodaysTasks();
    }
  }

  Widget _buildProgressLevelSelector() {
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
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getProgressColor(_currentProgressLevel)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getProgressColor(_currentProgressLevel)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getProgressIcon(_currentProgressLevel),
                        color: _getProgressColor(_currentProgressLevel),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentProgressLevel/10',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _getProgressColor(_currentProgressLevel),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: _currentProgressLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_currentProgressLevel',
              onChanged: (value) {
                _adjustProgressLevel(value.round());
              },
            ),
            Text(
              _getProgressDescription(_currentProgressLevel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressDescription(int level) {
    switch (level) {
      case 1:
        return 'Beginner - Very Easy tasks to get started';
      case 2:
        return 'Beginner - Easy daily habits';
      case 3:
        return 'Elementary - Light activities and routines';
      case 4:
        return 'Elementary - Moderate health practices';
      case 5:
        return 'Intermediate - Regular wellness activities';
      case 6:
        return 'Intermediate - Challenging health goals';
      case 7:
        return 'Advanced - Demanding fitness routines';
      case 8:
        return 'Advanced - Intensive health management';
      case 9:
        return 'Expert - Very challenging activities';
      case 10:
        return 'Expert - Maximum difficulty goals';
      default:
        return 'Beginner level';
    }
  }

  Widget _buildAIGuidanceCard() {
    if (_aiGuidance.isEmpty) return const SizedBox.shrink();

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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('🤖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Health Guidance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiGuidance,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;
  final int progressLevel; // 1-10 progress levels
  final String? aiPrompt; // Store original AI prompt/recommendation

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
    this.progressLevel = 1,
    this.aiPrompt,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
    int? progressLevel,
    String? aiPrompt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      progressLevel: progressLevel ?? this.progressLevel,
      aiPrompt: aiPrompt ?? this.aiPrompt,
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
      'progressLevel': progressLevel,
      'aiPrompt': aiPrompt,
    };
  }

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category:
          TaskCategory.values.firstWhere((c) => c.name == json['category']),
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      progressLevel: json['progressLevel'] ?? 1,
      aiPrompt: json['aiPrompt'],
    );
  }
}

enum TaskCategory {
  health,
  fitness,
  wellness,
  safety,
  planning,
  nutrition,
  mental,
  environmental,
  social,
  education
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
      case TaskCategory.nutrition:
        return 'Nutrition';
      case TaskCategory.mental:
        return 'Mental Health';
      case TaskCategory.environmental:
        return 'Environment';
      case TaskCategory.social:
        return 'Social';
      case TaskCategory.education:
        return 'Education';
      default:
        return 'Other';
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
      case TaskCategory.nutrition:
        return '🥗';
      case TaskCategory.mental:
        return '🧠';
      case TaskCategory.environmental:
        return '🌱';
      case TaskCategory.social:
        return '👥';
      case TaskCategory.education:
        return '📚';
      default:
        return '📝';
    }
  }

  // Get Material Icon for UI components
  IconData get materialIcon {
    switch (this) {
      case TaskCategory.health:
        return Icons.health_and_safety;
      case TaskCategory.fitness:
        return Icons.fitness_center;
      case TaskCategory.wellness:
        return Icons.spa;
      case TaskCategory.safety:
        return Icons.security;
      case TaskCategory.planning:
        return Icons.event_note;
      case TaskCategory.nutrition:
        return Icons.restaurant;
      case TaskCategory.mental:
        return Icons.psychology;
      case TaskCategory.environmental:
        return Icons.eco;
      case TaskCategory.social:
        return Icons.people;
      case TaskCategory.education:
        return Icons.school;
      default:
        return Icons.task_alt;
    }
  }

  // Get category color
  Color get color {
    switch (this) {
      case TaskCategory.health:
        return Colors.red.shade400;
      case TaskCategory.fitness:
        return Colors.orange.shade400;
      case TaskCategory.wellness:
        return Colors.purple.shade400;
      case TaskCategory.safety:
        return Colors.blue.shade400;
      case TaskCategory.planning:
        return Colors.grey.shade600;
      case TaskCategory.nutrition:
        return Colors.green.shade400;
      case TaskCategory.mental:
        return Colors.indigo.shade400;
      case TaskCategory.environmental:
        return Colors.teal.shade400;
      case TaskCategory.social:
        return Colors.pink.shade400;
      case TaskCategory.education:
        return Colors.amber.shade600;
      default:
        return Colors.brown.shade400;
    }
  }
}
