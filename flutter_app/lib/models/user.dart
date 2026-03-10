class User {
  final String id;
  final String username;
  final String name;
  final String role; // 'salesperson' or 'kitchen'

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'name': name, 'role': role};
  }

  bool get isSalesperson => role == 'salesperson';
  bool get isKitchen => role == 'kitchen';
}

// Default users for fallback (production uses Laravel API)
final List<User> defaultUsers = [
  User(id: '1', username: 'sales1', name: 'John Sales', role: 'salesperson'),
  User(id: '2', username: 'sales2', name: 'Jane Sales', role: 'salesperson'),
  User(id: '3', username: 'kitchen1', name: 'Chef Mike', role: 'kitchen'),
  User(id: '4', username: 'kitchen2', name: 'Chef Sarah', role: 'kitchen'),
];

// Default passwords (demo only)
final Map<String, String> defaultPasswords = {
  'sales1': '1234',
  'sales2': '1234',
  'kitchen1': '1234',
  'kitchen2': '1234',
};
