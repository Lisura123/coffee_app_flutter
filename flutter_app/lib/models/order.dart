class OrderItem {
  final String? id;
  final String? orderId;
  final String menuItemId;
  final String menuItemName;
  final int quantity;

  OrderItem({
    this.id,
    this.orderId,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString(),
      orderId: json['order_id']?.toString(),
      menuItemId: json['menu_item_id']?.toString() ?? '',
      menuItemName: json['menu_item_name'] ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': int.tryParse(menuItemId) ?? menuItemId,
      'menu_item_name': menuItemName,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final int tableNumber;
  final String status; // 'pending', 'preparing', 'completed', 'cancelled'
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem>? items;
  final String? createdByName;

  Order({
    required this.id,
    required this.tableNumber,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.createdByName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['id'].toString(),
      tableNumber: json['table_number'] is int
          ? json['table_number']
          : int.tryParse(json['table_number'].toString()) ?? 0,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      items: items,
      createdByName: json['created_by_name'],
    );
  }

  Order copyWith({String? status, String? updatedAt}) {
    return Order(
      id: id,
      tableNumber: tableNumber,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items,
      createdByName: createdByName,
    );
  }
}
