class Task {
  final String id;
  final String title;
  final String type; // e.g., PROJECT, ASSIGNMENT, QUIZ
  final DateTime dueDate;
  final String? timeString;
  final bool isHighPriority;
  final String? description;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.timeString,
    this.isHighPriority = false,
    this.description,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? dueDate,
    String? timeString,
    bool? isHighPriority,
    String? description,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      timeString: timeString ?? this.timeString,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Convert a Task into a Map (for saving)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'timeString': timeString,
      'isHighPriority': isHighPriority,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  // Extract a Task object from a Map (for loading)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      dueDate: DateTime.parse(json['dueDate']),
      timeString: json['timeString'],
      isHighPriority: json['isHighPriority'] ?? false,
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
