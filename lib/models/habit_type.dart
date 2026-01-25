class HabitType {
  final int id;
  final String userId;
  final String name;
  final int iconCode;
  final String colorHex;
  final DateTime createdAt;

  HabitType({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.createdAt,
  });

  factory HabitType.fromJson(Map<String, dynamic> json) {
    return HabitType(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] as int,
      colorHex: json['color_hex'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
