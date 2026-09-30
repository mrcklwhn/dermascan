class Practice {
  final String id;
  final String name;
  final String email;
  final String keyVerifier;

  Practice({
    required this.id,
    required this.name,
    required this.email,
    required this.keyVerifier,
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['practice_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      keyVerifier: json['key_verifier'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'practice_id': id,
      'name': name,
      'email': email,
      'key_verifier': keyVerifier,
    };
  }
}
