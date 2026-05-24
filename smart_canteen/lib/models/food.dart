class Food {
  final int id;
  final String name;
  final double price;
  final String? image;
  final String category;
  final bool isVeg;
  final String? description;

  Food({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    required this.category,
    required this.isVeg,
    this.description,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      image: json['image'],
      category: json['category'] ?? '',
      isVeg: json['is_veg'] == 1,
      description: json['description'],
    );
  }
}
