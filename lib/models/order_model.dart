import '../models/product_model.dart';

class Order {
  final int? id;
  final double total;
  final double discount;
  final double finalTotal;
  final DateTime date;
  final String status;
  final String paymentMethod;
  final String cardHolder;
  final String cardLast4;
  final String? promoCode;
  final List<Product> items;

  Order({
    this.id,
    required this.total,
    required this.discount,
    required this.finalTotal,
    required this.date,
    required this.status,
    required this.paymentMethod,
    required this.cardHolder,
    required this.cardLast4,
    this.promoCode,
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
      discount: (map['discount'] as num? ?? 0).toDouble(),
      finalTotal: (map['final_total'] as num? ?? map['total'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String? ?? 'completed',
      paymentMethod: map['payment_method'] as String? ?? 'Credit',
      cardHolder: map['card_holder'] as String? ?? '',
      cardLast4: map['card_last4'] as String? ?? '****',
      promoCode: map['promo_code'] as String?,
      items: items,
    );
  }
}