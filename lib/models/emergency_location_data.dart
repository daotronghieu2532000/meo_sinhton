class EmergencyLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final double accuracy;

  EmergencyLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }

  factory EmergencyLocationData.fromJson(Map<String, dynamic> json) {
    return EmergencyLocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? ''),
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
    );
  }

  String get googleMapsUrl {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  String get locationMessage {
    return '''
📍 Vị trí của tôi:
- Tọa độ: $latitude, $longitude
- Địa chỉ: $address
- Thời gian: $timestamp
- Độ chính xác: ±${accuracy.toStringAsFixed(1)}m

Link Google Maps: $googleMapsUrl
    ''';
  }
}
