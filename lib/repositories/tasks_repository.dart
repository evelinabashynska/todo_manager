import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// Абстрактний репозиторій для роботи з завданнями
abstract class TasksRepository {
  /// Отримати список завдань користувача
  Stream<List<TaskModel>> getTasks();

  /// Отримати завдання за ID
  Future<TaskModel?> getTaskById(String id);

  /// Додати нове завдання
  Future<void> addTask(TaskModel task);

  /// Оновити існуюче завдання
  Future<void> updateTask(TaskModel task);

  /// Видалити завдання
  Future<void> deleteTask(String id);

  /// Перемкнути статус виконання завдання
  Future<void> toggleTaskStatus(String id);
}

/// Реалізація репозиторію через Firestore
class FirestoreTasksRepository implements TasksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Колекція завдань конкретного користувача
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Користувач не авторизований');
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  @override
  Stream<List<TaskModel>> getTasks() {
    return _tasksCollection.orderBy('date', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Гарантуємо, що ID з Firestore потрапляє в модель
        data['id'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('Помилка отримання завдання: $e');
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Користувач не авторизований');

      // Створюємо посилання на новий документ, щоб отримати ID заздалегідь
      final docRef = task.id.isEmpty
          ? _tasksCollection.doc()
          : _tasksCollection.doc(task.id);

      final taskData = task.toJson();
      taskData['id'] = docRef.id; // Тепер ID документа і ID в полі збігаються!
      taskData['userId'] = userId;
      taskData['createdAt'] = FieldValue.serverTimestamp();
      taskData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(taskData);
    } catch (e) {
      throw Exception('Помилка створення завдання: $e');
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      if (task.id.isEmpty) {
        throw Exception('ID завдання не може бути порожнім');
      }

      final taskData = task.toJson();
      taskData['updatedAt'] = FieldValue.serverTimestamp();

      await _tasksCollection.doc(task.id).update(taskData);
    } catch (e) {
      throw Exception('Помилка оновлення завдання: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID завдання не може бути порожнім');
      }

      await _tasksCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Помилка видалення завдання: $e');
    }
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID завдання не може бути порожнім');
      }

      final doc = await _tasksCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Завдання не знайдено');
      }

      final currentStatus = doc.data()?['isCompleted'] ?? false;

      await _tasksCollection.doc(id).update({
        'isCompleted': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Помилка зміни статусу завдання: $e');
    }
  }
}

/// Моковий репозиторій для тестування (не використовує Firestore)
class MockTasksRepository implements TasksRepository {
  final List<TaskModel> _tasks = [];

  @override
  Stream<List<TaskModel>> getTasks() {
    return Stream.value(_tasks);
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    }
  }
}
