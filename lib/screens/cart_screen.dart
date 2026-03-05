import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'payment_screen.dart';
import 'order_history_screen.dart';

class CartScreen extends StatelessWidget {
  final List<Product> cartItems;
  final Function(int) onRemove;
  final VoidCallback onCheckoutComplete;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onRemove,
    required this.onCheckoutComplete,
  });

  @override
  Widget build(BuildContext context) {
    double total = cartItems.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFFF4B4B)),
            tooltip: 'Historial de órdenes',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Tu carrito está vacío",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (context, i) => Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(cartItems[i].image,
                              width: 50, height: 50, fit: BoxFit.cover),
                        ),
                        title: Text(cartItems[i].name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text("\$${cartItems[i].price}",
                            style: const TextStyle(
                                color: Color(0xFFFF4B4B))),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => onRemove(i),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildCheckoutSection(context, total),
              ],
            ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("\$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4B4B))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                // Abrir pantalla de pago con los datos del carrito
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      cartItems: List<Product>.from(cartItems),
                      total: total,
                      onPaymentComplete: onCheckoutComplete,
                    ),
                  ),
                );
              },
              child: const Text("PAGAR AHORA",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}