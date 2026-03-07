class WeatherData {
  final String condition;
  final double temperature;
  final String locationName;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String description;
  final DateTime timestamp;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.locationName,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.timestamp,
  });

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
