class User {
  final int id;
  final String username;
  final String? token;

  User({
    required this.id,
    required this.username,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      token: json['access'],
    );
  }
}