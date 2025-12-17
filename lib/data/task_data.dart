import '../models/task_model.dart';

class TaskData {
  static List<TaskModel> getTasks() {
    return [
      TaskModel(
        id: '1',
        title: 'Зробити зачіску',
        description: 'Накрутити волосся',
        date: '08.10.2025',
        priority: 'low',
        priorityLabel: 'Низький',
        isCompleted: false,
      ),
      TaskModel(
        id: '2',
        title: 'Приготувати вечерю',
        description: 'Рис з курочкою',
        date: '08.10.2025',
        priority: 'medium',
        priorityLabel: 'Середній',
        isCompleted: true,
      ),
      TaskModel(
        id: '3',
        title: 'Зробити лабораторну',
        description: 'З кросплатформного програмування',
        date: '08.10.2025',
        priority: 'high',
        priorityLabel: 'Високий',
        isCompleted: true,
      ),
    ];
  }
}
