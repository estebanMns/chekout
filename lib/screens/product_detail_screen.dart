
import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final Function(Product) onAdd;

  const ProductDetailScreen({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.network(product.image, height: 450, width: double.infinity, fit: BoxFit.cover),
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 450,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("\$${product.price}", style: const TextStyle(fontSize: 22, color: Color(0xFFFF4B4B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(product.description, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      onAdd(product);
                      Navigator.pop(context);
                    },
                    child: const Text("Add to Cart", style: TextStyle(color: Colors.white, fontSize: 18)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}