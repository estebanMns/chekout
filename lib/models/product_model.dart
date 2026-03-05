class Product {
  final String id, name, image, description, seller, category;
  final double price, rating;
  final List<String> gallery;

  Product({
    required this.id, required this.name, required this.price, 
    required this.image, required this.description, required this.gallery,
    required this.seller, required this.category, required this.rating,
  });
}