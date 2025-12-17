import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../repositories/tasks_repository.dart';

enum TaskLoadingState { initial, loading, loaded, error }

enum TaskActionState {
  idle,
  creating,
  updating,
  deleting,
  toggling,
  success,
  error,
}

class TaskProvider with ChangeNotifier {
  final TasksRepository _repository;

  // Стан завантаження списку
  TaskLoadingState _loadingState = TaskLoadingState.initial;
  String? _errorMessage;

  // Стан CRUD операцій
  TaskActionState _actionState = TaskActionState.idle;
  String? _actionError;

  // Дані
  List<TaskModel> _tasks = [];
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  // Фільтри
  int _selectedTabIndex = 0;
  String _sortBy = 'За датою';

  TaskProvider(this._repository);

  // Getters
  List<TaskModel> get tasks => _getFilteredTasks();
  TaskLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  TaskActionState get actionState => _actionState;
  String? get actionError => _actionError;
  int get selectedTabIndex => _selectedTabIndex;
  String get sortBy => _sortBy;

  List<TaskModel> get allTasks => _tasks;
  int get totalTasksCount => _tasks.length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get activeTasksCount => _tasks.where((t) => !t.isCompleted).length;

  /// Підписка на оновлення завдань з Firestore
  void subscribeToTasks() {
    _loadingState = TaskLoadingState.loading;
    notifyListeners();

    _tasksSubscription?.cancel();

    _tasksSubscription = _repository.getTasks().listen(
      (tasks) {
        _tasks = tasks;
        _loadingState = TaskLoadingState.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _loadingState = TaskLoadingState.error;
        _errorMessage = 'Помилка завантаження завдань: $error';
        notifyListeners();
      },
    );
  }

  /// Додавання нового завдання
  Future<bool> addTask(TaskModel task) async {
    _actionState = TaskActionState.creating;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.addTask(task);
      _actionState = TaskActionState.success;
      notifyListeners();

      // Повертаємо стан в idle через короткий час
      Future.delayed(const Duration(milliseconds: 500), () {
        _actionState = TaskActionState.idle;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _actionState = TaskActionState.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Оновлення завдання
  Future<bool> updateTask(TaskModel task) async {
    _actionState = TaskActionState.updating;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.updateTask(task);
      _actionState = TaskActionState.success;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _actionState = TaskActionState.idle;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _actionState = TaskActionState.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Видалення завдання
  Future<bool> deleteTask(String id) async {
    _actionState = TaskActionState.deleting;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.deleteTask(id);
      _actionState = TaskActionState.success;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _actionState = TaskActionState.idle;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _actionState = TaskActionState.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Перемикання статусу завдання
  Future<bool> toggleTaskStatus(String id) async {
    _actionState = TaskActionState.toggling;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.toggleTaskStatus(id);
      _actionState = TaskActionState.success;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _actionState = TaskActionState.idle;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _actionState = TaskActionState.error;
      _actionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Фільтрація завдань
  List<TaskModel> _getFilteredTasks() {
    List<TaskModel> filtered;

    switch (_selectedTabIndex) {
      case 1:
        filtered = _tasks.where((task) => !task.isCompleted).toList();
        break;
      case 2:
        filtered = _tasks.where((task) => task.isCompleted).toList();
        break;
      default:
        filtered = List.from(_tasks);
    }

    return _sortTasks(filtered);
  }

  /// Сортування завдань
  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    switch (_sortBy) {
      case 'За пріоритетом':
        tasks.sort((a, b) {
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          return (priorityOrder[a.priority] ?? 3).compareTo(
            priorityOrder[b.priority] ?? 3,
          );
        });
        break;
      case 'За назвою':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'За датою':
      default:
        tasks.sort((a, b) => a.date.compareTo(b.date));
    }
    return tasks;
  }

  /// Зміна вкладки
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  /// Зміна сортування
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// Пошук завдання за ID
  TaskModel? findTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Повторна спроба завантаження
  void retry() {
    subscribeToTasks();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
