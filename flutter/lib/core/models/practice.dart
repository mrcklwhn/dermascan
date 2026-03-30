class Practice {
  final String id;
  final String name;
  final String email;

  Practice({required this.id, required this.name, required this.email});

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'email': email};
  }
}
