class Task {
  final String id;
  final String title;
  final String type; // e.g., PROJECT, ASSIGNMENT, QUIZ
  final DateTime dueDate;
  final String?
  timeString; // e.g., '4:00 PM', '20 MINS' - for UI simplicity in prototype
  final bool isHighPriority; // To style the first card differently

  Task({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.timeString,
    this.isHighPriority = false,
  });
}
