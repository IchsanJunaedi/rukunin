class MarketplaceListingModel {
  final String id;
  final String communityId;
  final String sellerId;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerUnit;
  final String? sellerPhotoUrl;
  final String title;
  final String? description;
  final int? price;
  final String category; // 'makanan' | 'jasa' | 'barang' | 'tanaman' | 'lainnya'
  final List<String> images;
  final String status; // 'active' | 'sold'
  final int stock;
  final DateTime createdAt;

  const MarketplaceListingModel({
    required this.id,
    required this.communityId,
    required this.sellerId,
    this.sellerName,
    this.sellerPhone,
    this.sellerUnit,
    this.sellerPhotoUrl,
    required this.title,
    this.description,
    this.price,
    required this.category,
    required this.images,
    required this.status,
    this.stock = 1,
    required this.createdAt,
  });

  bool get isAvailable => status == 'active' && stock > 0;

  factory MarketplaceListingModel.fromMap(Map<String, dynamic> map) {
    final sellerProfile = map['profiles'] as Map<String, dynamic>?;
    final rawImages = map['images'];
    List<String> imageList = [];
    if (rawImages is List) {
      imageList = rawImages.map((e) => e.toString()).toList();
    }

    return MarketplaceListingModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      sellerId: map['seller_id'] as String,
      sellerName: sellerProfile?['full_name'] as String?,
      sellerPhone: sellerProfile?['phone'] as String?,
      sellerUnit: sellerProfile?['unit_number'] as String?,
      sellerPhotoUrl: sellerProfile?['photo_url'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      price: map['price'] != null ? (map['price'] as num).toInt() : null,
      category: map['category'] as String? ?? 'lainnya',
      images: imageList,
      status: map['status'] as String? ?? 'active',
      stock: (map['stock'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedPrice {
    if (price == null || price == 0) return 'Gratis / Nego';
    
    final formattedStr = price!.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.'
    );
    return 'Rp $formattedStr';
  }

  String get categoryLabel {
    return switch (category) {
      'makanan' => '🍱 Makanan',
      'jasa' => '🔧 Jasa',
      'barang' => '📦 Barang',
      'tanaman' => '🌿 Tanaman',
      _ => '🛍️ Lainnya',
    };
  }
}
