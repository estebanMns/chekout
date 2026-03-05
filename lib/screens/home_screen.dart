import 'package:chekout/widgets/product_card.dart';
import 'package:flutter/material.dart';
//import 'package:prostore/widgets/product_card.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  final Function(Product) onAdd;

  HomeScreen({super.key, required this.onAdd});

  // Dataset basado en el diseño de la imagen
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Light Brown Coat',
      price: 120.0,
      image: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80',
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Read more',
      seller: 'Jenny Doe',
      category: 'Clothes',
      rating: 4.5,
      gallery: [
        'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80',
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?q=80',
      ],
    ),
    Product(
      id: '2',
      name: 'Classic Watch',
      price: 85.0,
      image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80',
      description: 'Elegante reloj minimalista para cualquier ocasión.',
      seller: 'Watch Store',
      category: 'Watch',
      rating: 4.8,
      gallery: ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSpecialOffers(),
            _buildCategories(),
            _buildFlashSaleSection(context),
          ],
        ),
      ),
    );
  }

  // 1. Header Rojo con Ubicación y Buscador
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFFFF4B4B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Location", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 14),
                      Text(" New York, USA ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.tune, color: Colors.white),
              )
            ],
          ),
        ],
      ),
    );
  }

  // 2. Banner de Ofertas Especiales
  Widget _buildSpecialOffers() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("#SpecialForYou", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("See All", style: TextStyle(color: Color(0xFFFF4B4B))),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(colors: [Colors.black54, Colors.transparent]),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: const Text("Limited time!", style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  const SizedBox(height: 10),
                  const Text("Get Special Offer\nUp to 40%", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Listado de Categorías
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("See All", style: TextStyle(color: Color(0xFFFF4B4B))),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _catItem(Icons.checkroom, "Clothes"),
              _catItem(Icons.kitchen, "Electronics"),
              _catItem(Icons.directions_run, "Shoes"),
              _catItem(Icons.watch, "Watch"),
            ],
          )
        ],
      ),
    );
  }

  Widget _catItem(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(icon, color: const Color(0xFFFF4B4B))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // 4. Grid de Productos (Flash Sale)
  Widget _buildFlashSaleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Flash Sale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, i) {
              return ProductCard(
                product: _products[i],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ProductDetailScreen(
                        product: _products[i],
                        onAdd: onAdd,
                      ),
                    ),
                  );
                },
                onAdd: () => onAdd(_products[i]),
              );
            },
          )
        ],
      ),
    );
  }
}