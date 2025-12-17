import 'package:flutter/material.dart';
import 'package:todo_manager/models/task_model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/task_card.dart';
import '../widgets/task_tab.dart';
import '../widgets/task_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../utils/responsive_helper.dart';
import '../services/auth_service.dart';
import '../providers/task_provider.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _analytics = FirebaseAnalytics.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;

    // Завантаження завдань
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().subscribeToTasks();
    });

    // Analytics
    _analytics.logScreenView(
      screenName: 'HomeScreen',
      screenClass: 'HomeScreen',
    );

    if (_currentUser != null) {
      _analytics.setUserId(id: _currentUser!.uid);
      _analytics.setUserProperty(
        name: 'user_email',
        value: _currentUser!.email,
      );
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вихід'),
        content: const Text('Ви впевнені, що хочете вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Профіль користувача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentUser?.displayName != null) ...[
              const Text(
                'Ім\'я:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_currentUser!.displayName!),
              const SizedBox(height: 12),
            ],
            const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currentUser?.email ?? 'Невідомо'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрити'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({TaskModel? task, int? taskIndex}) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onSave: (newTask) async {
          final provider = context.read<TaskProvider>();
          bool success;

          if (task == null) {
            // Створення нового завдання
            success = await provider.addTask(newTask);
            if (success) {
              _analytics.logEvent(name: 'task_created');
              _showSnackbar('Завдання створено');
            } else {
              _showErrorSnackbar(provider.actionError ?? 'Помилка створення');
            }
          } else {
            // Оновлення існуючого завдання
            success = await provider.updateTask(newTask);
            if (success) {
              _analytics.logEvent(name: 'task_updated');
              _showSnackbar('Завдання оновлено');
            } else {
              _showErrorSnackbar(provider.actionError ?? 'Помилка оновлення');
            }
          }
        },
      ),
    );
  }

  Future<void> _handleDelete(TaskModel task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteConfirmationDialog(),
    );

    if (shouldDelete == true) {
      final provider = context.read<TaskProvider>();
      final success = await provider.deleteTask(task.id);

      if (success) {
        _analytics.logEvent(name: 'task_deleted');
        _showSnackbar('Завдання видалено');
      } else {
        _showErrorSnackbar(provider.actionError ?? 'Помилка видалення');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Обробка станів завантаження
          if (taskProvider.loadingState == TaskLoadingState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.loadingState == TaskLoadingState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    taskProvider.errorMessage ?? 'Помилка завантаження',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => taskProvider.retry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Спробувати знову'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(isMobile, taskProvider),
              Expanded(child: _buildTaskList(isMobile, taskProvider)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: Text(
        'Мої завдання',
        style: TextStyle(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.language,
            color: AppColors.textPrimary,
            size: isMobile ? 20 : 24,
          ),
          onPressed: () {},
        ),
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 8 : 12),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: isMobile ? 36 : 40,
              height: isMobile ? 36 : 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Center(
                child: Text(
                  _getUserInitial(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? 'Користувач',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Divider(height: 20),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Профіль'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Вийти', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                _showUserProfile();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ),
      ],
    );
  }

  String _getUserInitial() {
    if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName![0].toUpperCase();
    } else if (_currentUser?.email != null) {
      return _currentUser!.email![0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildHeader(bool isMobile, TaskProvider provider) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddButton(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          isMobile ? _buildMobileTabs(provider) : _buildDesktopTabs(provider),
        ],
      ),
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showTaskDialog(),
        icon: Icon(Icons.add, size: isMobile ? 18 : 20),
        label: Text(
          'Додати завдання',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMobileTabs(TaskProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TaskTab(
                label: 'Всі',
                index: AppConstants.tabAll,
                selectedIndex: provider.selectedTabIndex,
                onTap: provider.setSelectedTab,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TaskTab(
                label: 'Активні',
                index: AppConstants.tabActive,
                selectedIndex: provider.selectedTabIndex,
                onTap: provider.setSelectedTab,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TaskTab(
                label: 'Завершені',
                index: AppConstants.tabCompleted,
                selectedIndex: provider.selectedTabIndex,
                onTap: provider.setSelectedTab,
                isMobile: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSortDropdown(true, provider),
      ],
    );
  }

  Widget _buildDesktopTabs(TaskProvider provider) {
    return Row(
      children: [
        TaskTab(
          label: 'Всі',
          index: AppConstants.tabAll,
          selectedIndex: provider.selectedTabIndex,
          onTap: provider.setSelectedTab,
        ),
        TaskTab(
          label: 'Активні',
          index: AppConstants.tabActive,
          selectedIndex: provider.selectedTabIndex,
          onTap: provider.setSelectedTab,
        ),
        TaskTab(
          label: 'Завершені',
          index: AppConstants.tabCompleted,
          selectedIndex: provider.selectedTabIndex,
          onTap: provider.setSelectedTab,
        ),
        const Spacer(),
        _buildSortDropdown(false, provider),
      ],
    );
  }

  Widget _buildSortDropdown(bool isMobile, TaskProvider provider) {
    return PopupMenuButton<String>(
      initialValue: provider.sortBy,
      child: Container(
        width: isMobile ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            Text(
              provider.sortBy,
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
            SizedBox(width: isMobile ? 4 : 8),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
      onSelected: provider.setSortBy,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'За датою', child: Text('За датою')),
        const PopupMenuItem(
          value: 'За пріоритетом',
          child: Text('За пріоритетом'),
        ),
        const PopupMenuItem(value: 'За назвою', child: Text('За назвою')),
      ],
    );
  }

  Widget _buildTaskList(bool isMobile, TaskProvider provider) {
    if (provider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Немає завдань',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        return TaskCard(
          task: task,
          isMobile: isMobile,
          onCheckboxChanged: (value) async {
            final success = await provider.toggleTaskStatus(task.id);
            if (success && value) {
              _analytics.logEvent(name: 'task_completed');
              _showSnackbar('Завдання виконано');
            } else if (!success) {
              _showErrorSnackbar(
                provider.actionError ?? 'Помилка зміни статусу',
              );
            }
          },
          onDelete: () => _handleDelete(task),
          onEdit: () => _showTaskDialog(task: task),
        );
      },
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Кнопка тесту Crashlytics (видаліть в продакшені)
        FloatingActionButton(
          heroTag: 'crash_test',
          onPressed: _testCrashlytics,
          backgroundColor: Colors.red,
          mini: true,
          child: const Icon(Icons.bug_report, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Основна кнопка допомоги
        FloatingActionButton(
          heroTag: 'help',
          onPressed: () {
            _analytics.logEvent(name: 'help_button_pressed');
          },
          backgroundColor: AppColors.black,
          child: const Icon(Icons.help_outline, color: AppColors.white),
        ),
      ],
    );
  }

  void _testCrashlytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Тест Crashlytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Виберіть тип помилки для тестування:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Фатальний краш'),
              subtitle: const Text('Застосунок закриється'),
              onTap: () {
                Navigator.pop(context);
                _analytics.logEvent(name: 'crash_test_fatal');
                // Фатальна помилка
                FirebaseCrashlytics.instance.crash();
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Нефатальна помилка'),
              subtitle: const Text('Застосунок продовжить роботу'),
              onTap: () {
                Navigator.pop(context);
                _analytics.logEvent(name: 'crash_test_nonfatal');
                // Нефатальна помилка
                FirebaseCrashlytics.instance.recordError(
                  Exception('Тестова нефатальна помилка'),
                  StackTrace.current,
                  reason: 'Тестування Crashlytics з HomeScreen',
                  fatal: false,
                );
                _showSnackbar('Нефатальна помилка відправлена в Crashlytics');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
        ],
      ),
    );
  }
}
