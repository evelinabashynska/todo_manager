class TaskModel {
  final String id;
  final String title;
  final String description; // Додано
  final String date;
  final String priority;
  final String priorityLabel;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.description, // Додано
    required this.date,
    required this.priority,
    required this.priorityLabel,
    this.isCompleted = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '', // Додано
      date: json['date'] ?? '',
      priority: json['priority'] ?? 'low',
      priorityLabel: json['priorityLabel'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description, // Додано
      'date': date,
      'priority': priority,
      'priorityLabel': priorityLabel,
      'isCompleted': isCompleted,
    };
  }
}
