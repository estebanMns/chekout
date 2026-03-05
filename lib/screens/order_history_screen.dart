import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = DatabaseHelper.instance.getAllOrders().then(
      (list) => list.map((m) => Order.fromMap(m)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        title: const Text("Mis Órdenes",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        centerTitle: true,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4C6EF5)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No tienes órdenes aún",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadOrders()),
            color: const Color(0xFF4C6EF5),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, i) => _buildOrderCard(orders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding:
            const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_rounded,
              color: Color(0xFF4C6EF5), size: 22),
        ),
        title: Text("Orden #${order.id}",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1A2E))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatDate(order.date),
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _statusBadge(order.status),
                if (order.promoCode != null &&
                    order.promoCode!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _promoBadge(order.promoCode!),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("\$${order.finalTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                    color: Color(0xFF4C6EF5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (order.discount > 0)
              Text("-\$${order.discount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        children: [
          const Divider(),

          // Info de pago
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _mastercardIcon(),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.cardHolder.isEmpty
                          ? order.paymentMethod
                          : order.cardHolder,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E)),
                    ),
                    Text(
                      '${order.paymentMethod} •••• ${order.cardLast4}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Productos
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Productos:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E))),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(product.category,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text("\$${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Color(0xFF4C6EF5),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Resumen de totales
          const Divider(height: 20),
          _totalRow('Subtotal', '\$${order.total.toStringAsFixed(2)}'),
          if (order.discount > 0)
            _totalRow('Descuento',
                '-\$${order.discount.toStringAsFixed(2)}',
                color: Colors.green),
          _totalRow('Total pagado',
              '\$${order.finalTotal.toStringAsFixed(2)}',
              isBold: true, color: const Color(0xFF4C6EF5)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600,
                  fontSize: isBold ? 16 : 13,
                  color: color ?? const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  Widget _promoBadge(String code) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(code,
            style: const TextStyle(
                color: Color(0xFF4C6EF5),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  Widget _mastercardIcon() => SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFEB001B))),
            ),
            Positioned(
              right: 0,
              child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF79E1B).withOpacity(0.9))),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}