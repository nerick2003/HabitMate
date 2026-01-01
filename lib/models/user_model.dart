class User {
  int? id;
  String name;
  String email;
  String? avatar; // Optional avatar/icon identifier
  DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.avatar,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar ?? 'person',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String? ?? 'person',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

