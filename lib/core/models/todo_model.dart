class Todo {
  final String? id;
  final String doctorId;
  final DateTime date;
  final String title;
  final String? description;
  final String priority;
  final bool completed;
  final String? time;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    this.id,
    required this.doctorId,
    required this.date,
    required this.title,
    this.description,
    required this.priority,
    required this.completed,
    this.time,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['_id'],
      doctorId: json['doctorId'] ?? '',
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? 'medium',
      completed: json['completed'] ?? false,
      time: json['time'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'priority': priority,
      'completed': completed,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    String? title,
    String? description,
    String? priority,
    bool? completed,
    String? time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}