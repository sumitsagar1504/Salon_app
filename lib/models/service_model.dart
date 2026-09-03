class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String imageUrl;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'imageUrl': imageUrl,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? imageUrl,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
