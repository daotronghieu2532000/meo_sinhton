class EmergencyShelter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // 'hospital', 'shelter', 'police', 'fire_station'
  final String phone;
  final String? description;
  final bool isAvailable24h;

  EmergencyShelter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.phone,
    this.description,
    this.isAvailable24h = false,
  });

  factory EmergencyShelter.fromJson(Map<String, dynamic> json) {
    return EmergencyShelter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      type: json['type'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'],
      isAvailable24h: json['isAvailable24h'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'phone': phone,
      'description': description,
      'isAvailable24h': isAvailable24h,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'hospital':
        return 'Bệnh viện';
      case 'police':
        return 'Công an';
      case 'fire_station':
        return 'Cửa hàng phòng cháy';
      default:
        return 'Nơi trú ẩn';
    }
  }

  String get displayPhone {
    return phone.isNotEmpty ? phone : 'Không có';
  }
}
