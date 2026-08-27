class Task {
  final String id;
  final String title;
  final String type;
  final DateTime dueDate;
  final String? timeString;
  final bool isHighPriority;
  final String? description;
  final bool isCompleted;
  final List<String> reminders;
  final List<String>? attachmentPaths;
  final double? marks;

  Task({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.timeString,
    this.isHighPriority = false,
    this.description,
    this.isCompleted = false,
    this.reminders = const [],
    this.attachmentPaths,
    this.marks,
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
    List<String>? reminders,
    List<String>? attachmentPaths,
    double? marks,
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
      reminders: reminders ?? this.reminders,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      marks: marks ?? this.marks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'timeString': timeString,
      'isHighPriority': isHighPriority ? 1 : 0,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'reminders': reminders.join(','),
      'attachmentPaths': attachmentPaths?.join(','),
      'marks': marks,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      dueDate: DateTime.parse(map['dueDate']),
      timeString: map['timeString'],
      isHighPriority: map['isHighPriority'] == 1,
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      reminders:
          map['reminders'] != null && map['reminders'].toString().isNotEmpty
          ? map['reminders'].toString().split(',')
          : [],
      attachmentPaths:
          map['attachmentPaths'] != null &&
              map['attachmentPaths'].toString().isNotEmpty
          ? map['attachmentPaths'].toString().split(',')
          : [],
      marks: map['marks'] != null ? (map['marks'] as num).toDouble() : null,
    );
  }
}
