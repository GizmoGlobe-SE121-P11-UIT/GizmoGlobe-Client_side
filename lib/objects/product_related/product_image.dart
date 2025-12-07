class ProductImage {
  final String imageId;
  final int position;
  final String url;

  ProductImage({
    required this.imageId,
    required this.position,
    required this.url,
  });

  factory ProductImage.fromMap(String id, Map<String, dynamic> data) {
    return ProductImage(
      imageId: id,
      position: (data['position'] as num?)?.toInt() ?? 0,
      url: data['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'url': url,
    };
  }
}
