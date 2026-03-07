import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // Bạn cần một API Key từ OpenWeatherMap (Miễn phí)
  // Đăng ký tại: https://openweathermap.org/api
  static const String _apiKey = '46d5191240ac68f6c11817c11e09cb60'; 
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherData?> getWeather(double lat, double lon) async {
    try {
      final weatherUrl = '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi';
      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        WeatherData weather = WeatherData.fromJson(data);
        
        // Fetch Air Pollution data
        final airQuality = await getAirQuality(lat, lon);
        return weather.copyWith(airQuality: airQuality);
      } else {
        print('Error fetching weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception fetching weather: $e');
      return null;
    }
  }

  static Future<AirQuality?> getAirQuality(double lat, double lon) async {
    final airUrl = 'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(airUrl));
      if (response.statusCode == 200) {
        return AirQuality.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching air quality: $e');
    }
    return null;
  }

  // Mock weather for testing if no API key
  static Future<WeatherData> getMockWeather(double lat, double lon) async {
    await Future.delayed(const Duration(seconds: 1));
    return WeatherData(
      condition: 'Rain',
      temperature: 25.5,
      locationName: 'Đà Nẵng',
      icon: '10d',
      humidity: 85,
      windSpeed: 18.0,
      description: 'Mưa vừa, có thể có dông',
      timestamp: DateTime.now(),
    );
  }
}
