/// Entidade Store do domínio.
///
/// Referência: ARCHITECTURE.md §ERD: STORES
class Store {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final double rating;
  final bool isActive;
  final String? estimatedDeliveryTime;

  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.rating = 0.0,
    required this.isActive,
    this.estimatedDeliveryTime,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      description: json['description'] as String?,
      latitude: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num).toDouble(),
      longitude: (json['lng'] as num?)?.toDouble() ?? (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      estimatedDeliveryTime: json['estimated_delivery_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'distance_km': distanceKm,
        'rating': rating,
        'is_active': isActive,
        'estimated_delivery_time': estimatedDeliveryTime,
      };
}
