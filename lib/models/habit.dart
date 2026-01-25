class Habit {
  final int id;
  final String userId;
  final int habitTypeId;
  final DateTime date;
  final String habitName;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.habitTypeId,
    required this.date,
    required this.habitName,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      habitTypeId: json['habit_type_id'] as int,
      date: DateTime.parse(json['date'] as String),
      habitName: json['habit_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_type_id': habitTypeId,
      'date': date.toIso8601String().split('T')[0],
      'habit_name': habitName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
