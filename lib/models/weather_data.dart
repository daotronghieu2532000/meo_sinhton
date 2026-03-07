class AirQuality {
  final int aqi; // Air Quality Index (1-5)
  final double pm2_5;
  final double pm10;
  final double co;
  final double no2;
  final double o3;
  final double so2;

  AirQuality({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.o3,
    required this.so2,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final list = json['list'][0];
    final components = list['components'];
    return AirQuality(
      aqi: list['main']['aqi'],
      pm2_5: components['pm2_5'].toDouble(),
      pm10: components['pm10'].toDouble(),
      co: components['co'].toDouble(),
      no2: components['no2'].toDouble(),
      o3: components['o3'].toDouble(),
      so2: components['so2'].toDouble(),
    );
  }

  String get aqiStatus {
    switch (aqi) {
      case 1: return 'Tốt';
      case 2: return 'Khá';
      case 3: return 'Trung bình';
      case 4: return 'Kém';
      case 5: return 'Rất kém';
      default: return 'Không xác định';
    }
  }

  String get aqiAdvice {
    switch (aqi) {
      case 1: return 'Không khí trong lành, hãy tận hưởng!';
      case 2: return 'Chất lượng không khí chấp nhận được.';
      case 3: return 'Người nhạy cảm nên hạn chế ra ngoài lâu.';
      case 4: return 'Có hại cho sức khỏe, nên đeo khẩu trang.';
      case 5: return 'Nguy hại! Hãy ở trong nhà và đóng cửa sổ.';
      default: return '';
    }
  }
}

class WeatherData {
  final String condition;
  final double temperature;
  final String locationName;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String description;
  final DateTime timestamp;
  final AirQuality? airQuality;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.locationName,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.timestamp,
    this.airQuality,
  });

  WeatherData copyWith({
    String? condition,
    double? temperature,
    String? locationName,
    String? icon,
    int? humidity,
    double? windSpeed,
    String? description,
    DateTime? timestamp,
    AirQuality? airQuality,
  }) {
    return WeatherData(
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      locationName: locationName ?? this.locationName,
      icon: icon ?? this.icon,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      airQuality: airQuality ?? this.airQuality,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    
    return WeatherData(
      condition: weather['main'],
      description: weather['description'],
      icon: weather['icon'],
      temperature: main['temp'].toDouble(),
      humidity: main['humidity'],
      windSpeed: wind['speed'].toDouble(),
      locationName: json['name'],
      timestamp: DateTime.now(),
    );
  }

  bool get isSevere => 
    condition.toLowerCase().contains('storm') || 
    condition.toLowerCase().contains('thunderstorm') ||
    windSpeed > 15; // Ví dụ: trên 15m/s là bắt đầu nguy hiểm
    
  String get alertMessage {
    if (condition.toLowerCase().contains('storm')) return '⚠️ Cảnh báo bão!';
    if (condition.toLowerCase().contains('thunderstorm')) return '⚡ Cảnh báo dông sét!';
    if (windSpeed > 15) return '💨 Cảnh báo gió mạnh!';
    return '';
  }
}
