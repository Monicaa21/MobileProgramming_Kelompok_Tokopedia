class ShoppingItem {
  final String sku;
  final String id;
  final String brand;
  final String category;
  final String description;
  final int discountPercentage;
  final List<String> images;
  final int price;
  final int stock;
  final double rating;
  final String thumbnail;
  final String title;
  final String video;

  ShoppingItem({
    required this.sku,
    required this.id,
    required this.brand,
    required this.category,
    required this.description,
    required this.discountPercentage,
    required this.images,
    required this.price,
    required this.stock,
    required this.rating,
    required this.thumbnail,
    required this.title,
    required this.video,
  });

  Map<String, dynamic> toJson() => {
    'sku': sku,
    '_id': id,
    'brand': brand,
    'category': category,
    'description': description,
    'discountPercentage': discountPercentage,
    'images': images,
    'price': price,
    'stock': stock,
    'rating': rating,
    'thumbnail': thumbnail,
    'title': title,
    'video': video,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      sku: json['sku']?.toString() ?? '',
      id: json['_id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toInt() ?? 0,
      images: List<String>.from(json['images'] ?? []),
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      video: json['video']?.toString() ?? '',
    );
  }
}
