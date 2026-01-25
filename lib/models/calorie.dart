class Calorie {
  final int id;
  final int calories;
  final String mealName;
  final DateTime createdAt;
  final String? userId;

  Calorie({
    required this.id,
    required this.calories,
    required this.mealName,
    required this.createdAt,
    this.userId,
  });

  factory Calorie.fromJson(Map<String, dynamic> json) {
    return Calorie(
      id: json['id'] as int,
      calories: json['calories'] as int,
      mealName: json['meal_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calories': calories,
      'meal_name': mealName,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}
