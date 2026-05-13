class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final bool isAvailable;
  final List<String> tags;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.isAvailable = true,
    this.tags = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isAvailable: json['is_available'] as bool? ?? true,
        tags: List<String>.from(json['tags'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'image_url': imageUrl,
        'description': description,
        'is_available': isAvailable,
        'tags': tags,
      };
}

// Sample menu data for development/testing
final List<MenuItem> sampleMenu = [
  const MenuItem(
    id: '1', name: 'Chicken Adobo', category: 'Mains',
    price: 185, imageUrl: 'assets/images/chicken-adobo.jpg', description: 'Classic Filipino adobo with tender chicken, slow-cooked in vinegar, soy sauce, and garlic.',
    tags: ['bestseller'],
  ),
  const MenuItem(
    id: '2', name: 'Pork Sinigang', category: 'Mains',
    price: 195, imageUrl: '', description: 'Sour tamarind broth with pork ribs and fresh vegetables.',
    tags: ['spicy'],
  ),
  const MenuItem(
    id: '3', name: 'Beef Kare-Kare', category: 'Mains',
    price: 220, imageUrl: '', description: 'Rich peanut-based stew with tender oxtail and vegetables.',
    tags: [],
  ),
  const MenuItem(
    id: '4', name: 'Pork Sisig', category: 'Mains',
    price: 175, imageUrl: '', description: 'Sizzling chopped pork with onions, chili, and calamansi.',
    tags: ['bestseller', 'spicy'],
  ),
  const MenuItem(
    id: '5', name: 'Steamed Rice', category: 'Rice & Sides',
    price: 35, imageUrl: '', description: 'Plain steamed white rice.',
    tags: [],
  ),
  const MenuItem(
    id: '6', name: 'Garlic Fried Rice', category: 'Rice & Sides',
    price: 55, imageUrl: '', description: 'Fragrant garlic fried rice with egg.',
    tags: ['bestseller'],
  ),
  const MenuItem(
    id: '7', name: 'Lumpia Shanghai', category: 'Rice & Sides',
    price: 95, imageUrl: '', description: '6 pieces crispy pork spring rolls with sweet chili sauce.',
    tags: [],
  ),
  const MenuItem(
    id: '8', name: 'Pancit Bihon', category: 'Rice & Sides',
    price: 135, imageUrl: '', description: 'Stir-fried rice noodles with vegetables and pork.',
    tags: [],
  ),
  const MenuItem(
    id: '9', name: 'Calamansi Juice', category: 'Drinks',
    price: 65, imageUrl: '', description: 'Fresh Philippine lime juice, served cold.',
    tags: ['bestseller'],
  ),
  const MenuItem(
    id: '10', name: 'Iced Tea', category: 'Drinks',
    price: 55, imageUrl: '', description: 'House-brewed iced tea, free refill.',
    tags: [],
  ),
  const MenuItem(
    id: '11', name: 'Soda (can)', category: 'Drinks',
    price: 45, imageUrl: '', description: 'Pepsi, 7Up, or Mountain Dew.',
    tags: [],
  ),
  const MenuItem(
    id: '12', name: 'Leche Flan', category: 'Desserts',
    price: 85, imageUrl: '', description: 'Classic Filipino caramel custard.',
    tags: ['bestseller'],
  ),
  const MenuItem(
    id: '13', name: 'Halo-Halo', category: 'Desserts',
    price: 120, imageUrl: '', description: 'Mixed shaved ice with ube, leche flan, and sweet beans.',
    tags: [],
  ),
];