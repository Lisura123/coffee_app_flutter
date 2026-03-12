class MenuItem {
  final String id;
  final String name;
  final String category;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    this.category = 'beverages',
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? 'beverages',
      available: json['available'] == true || json['available'] == 1,
    );
  }
}

// Default menu items (used if no database)
final List<MenuItem> defaultMenuItems = [
  MenuItem(id: '1', name: 'Water', category: 'beverages', available: true),
  MenuItem(id: '2', name: 'Tea', category: 'beverages', available: true),
  MenuItem(id: '3', name: 'Coffee', category: 'beverages', available: true),
  MenuItem(
    id: '4',
    name: 'Hot Chocolate',
    category: 'beverages',
    available: true,
  ),
  MenuItem(id: '5', name: 'Ginger Tea', category: 'beverages', available: true),
];
