import '../models/product_model.dart';

class Order {
  final int? id;
  final double total;
  final DateTime date;
  final String status;
  final List<Product> items;

  Order({
    this.id,
    required this.total,
    required this.date,
    required this.status,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((item) {
      final m = item as Map<String, dynamic>;
      return Product(
        id: m['product_id'] as String,
        name: m['product_name'] as String,
        price: (m['product_price'] as num).toDouble(),
        image: m['product_image'] as String,
        description: '',
        gallery: [],
        seller: m['product_seller'] as String,
        category: m['product_category'] as String,
        rating: 0.0,
      );
    }).toList();

    return Order(
      id: map['id'] as int?,
      total: (map['total'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}