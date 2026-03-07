import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/emergency_location_manager.dart';
import '../models/emergency_shelter.dart';
import '../app/app_strings.dart';
import '../utils/permission_helper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyMapScreen extends StatefulWidget {
  const EmergencyMapScreen({
    super.key,
    required this.appController,
    required this.isEnglish,
  });

  final dynamic appController; // AppController type
  final bool isEnglish;

  @override
  State<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends State<EmergencyMapScreen> {
  Position? _currentPosition;
  List<EmergencyShelter> _shelters = [];
  List<EmergencyShelter> _nearbyShelters = [];
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  String _searchQuery = '';
  bool _isSearching = false;
  
  // New variables for Map and Weather
  final MapController _mapController = MapController();
  WeatherData? _weather;
  String? _currentAddress;
  bool _showMap = true;
  bool _isWeatherLoading = false;


  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Request all emergency permissions first
      bool permissionsGranted = await PermissionHelper.requestAllEmergencyPermissions(
        context,
        widget.isEnglish,
      );
      
      if (!permissionsGranted) {
        setState(() {
          _isLoading = false;
          _locationPermissionGranted = false;
        });
        return;
      }

      setState(() {
        _locationPermissionGranted = true;
      });

      // Get current position
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        // Khởi chạy song song cả 2 tác vụ để tiết kiệm thời gian
        await Future.wait([
          _loadShelters(),
          _loadWeather(),
        ]);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeather() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _isWeatherLoading = true;
    });

    try {
      // Thử lấy weather thực tế, nếu chưa có API key thì dùng Mock
      var weather = await WeatherService.getWeather(
        _currentPosition!.latitude, 
        _currentPosition!.longitude
      );
      
      if (weather == null) {
        weather = await WeatherService.getMockWeather(
          _currentPosition!.latitude, 
          _currentPosition!.longitude
        );
      }

      // Reverse geocoding for precise location name
      final address = await LocationService.getAddressFromLocation(_currentPosition!);
      if (weather != null && address != 'Unknown location') {
        weather = weather.copyWith(locationName: address);
      }

      setState(() {
        _weather = weather;
        _currentAddress = address;
        _isWeatherLoading = false;
      });
    } catch (e) {
      print('Error loading weather: $e');
      setState(() {
        _isWeatherLoading = false;
      });
    }
  }

  Future<void> _loadShelters() async {
    if (_currentPosition == null) return;

    try {
      // 1. Hiển thị ngay lập tức danh sách tĩnh để app không bị trắng xóa
      final staticShelters = await EmergencyLocationManager.getAllShelters();
      setState(() {
        _shelters = staticShelters;
      });

      // 2. Load dữ liệu thực tế (OSM) từ mạng ở background
      final nearby = await EmergencyLocationManager.findNearbyShelters(radiusKm: 8.0);
      
      setState(() {
        // Gộp dữ liệu mới vào dữ liệu tĩnh một cách duy nhất
        final Map<String, EmergencyShelter> combinedMap = {};
        for (var s in staticShelters) combinedMap[s.id] = s;
        for (var s in nearby) combinedMap[s.id] = s;
        
        _shelters = combinedMap.values.toList();
        _nearbyShelters = nearby;
      });
    } catch (e) {
      print('Error loading shelters: $e');
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeLocation();
    await _loadWeather(); // Refresh weather too
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isEnglish ? 'Permissions Required' : 'Cần cấp quyền'),
        content: Text(
          widget.isEnglish
              ? 'LifeSpark needs location, SMS, and phone permissions to provide emergency features. These permissions could save your life in critical situations.'
              : 'LifeSpark cần quyền vị trí, SMS và gọi điện để cung cấp tính năng khẩn cấp. Các quyền này có thể cứu mạng bạn trong tình huống nguy cấp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initializeLocation();
            },
            child: Text(widget.isEnglish ? 'Grant All Permissions' : 'Cấp tất cả quyền'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyLocation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: Colors.red.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish ? 'Emergency SOS' : 'Khẩn cấp SOS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        widget.isEnglish
                            ? 'Send your location to emergency contacts'
                            : 'Gửi vị trí của bạn đến người liên lạc khẩn cấp',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Location info
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEnglish ? 'Your Location' : 'Vị trí của bạn',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📍 ${_currentPosition!.accuracy.toStringAsFixed(1)}m accuracy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await EmergencyLocationManager.shareEmergencyLocation(
                          message: widget.isEnglish
                              ? 'I need emergency help!'
                              : 'Tôi cần sự giúp đỡ khẩn cấp!',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.isEnglish
                                    ? 'Location shared successfully'
                                    : 'Đã chia sẻ vị trí thành công',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.isEnglish
                                    ? 'Failed to share location'
                                    : 'Không thể chia sẻ vị trí',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: Text(widget.isEnglish ? 'Share Location' : 'Chia sẻ vị trí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await EmergencyLocationManager.sendEmergencyLocationViaSMS(
                          emergencyContacts: ['0912345678'], // Lấy từ settings
                          message: widget.isEnglish
                              ? 'I need emergency help!'
                              : 'Tôi cần sự giúp đỡ khẩn cấp!',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.isEnglish
                                    ? 'SMS sent successfully'
                                    : 'Đã gửi SMS thành công',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.isEnglish
                                    ? 'Failed to send SMS'
                                    : 'Không thể gửi SMS',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.sms),
                    label: Text(widget.isEnglish ? 'Send SMS' : 'Gửi SMS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_locationPermissionGranted) {
      return _buildPermissionRequiredScreen();
    }

    if (_currentPosition == null) {
      return _buildLocationErrorScreen();
    }

    return _buildMapContent();
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEnglish ? 'Getting your location...' : 'Đang lấy vị trí của bạn...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequiredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.location_off,
                size: 64,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isEnglish ? 'Location Permission Required' : 'Cần quyền truy cập vị trí',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isEnglish
                  ? 'Please enable location access to use emergency features. This could save your life!'
                  : 'Vui lòng bật quyền truy cập vị trí để sử dụng tính năng khẩn cấp. Điều này có thể cứu mạng bạn!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showLocationPermissionDialog,
              icon: const Icon(Icons.security),
              label: Text(widget.isEnglish ? 'Grant Permissions' : 'Cấp quyền'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.gps_off,
                size: 64,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isEnglish ? 'Location Unavailable' : 'Không thể lấy vị trí',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isEnglish
                  ? 'Unable to get your current location. Please check your GPS settings.'
                  : 'Không thể lấy vị trí hiện tại. Vui lòng kiểm tra cài đặt GPS.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh),
              label: Text(widget.isEnglish ? 'Try Again' : 'Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard({bool isCompact = false}) {
    if (_isWeatherLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        height: isCompact ? 60 : null,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_weather == null) return const SizedBox.shrink();

    final isSevere = _weather!.isSevere;

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSevere 
              ? [Colors.orange.shade800, Colors.red.shade900]
              : [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isSevere ? Colors.red : Colors.blue).withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/${_weather!.icon}.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _weather!.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${_weather!.description[0].toUpperCase()}${_weather!.description.substring(1)} • AQI: ${_weather!.airQuality?.aqi ?? "?"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_weather!.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_weather!.windSpeed}m/s',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSevere 
            ? [Colors.orange.shade800, Colors.red.shade900]
            : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isSevere ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${_weather!.icon}@2x.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weather!.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _weather!.description[0].toUpperCase() + _weather!.description.substring(1),
                      style: TextStyle(
                        color: Colors.white.withAlpha(210), 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_weather!.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 26,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.air, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_weather!.windSpeed} m/s',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_weather!.airQuality != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (_weather!.airQuality!.aqi >= 4 ? Colors.orange : Colors.blue).withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.air_rounded, 
                          color: _weather!.airQuality!.aqi >= 4 ? Colors.orangeAccent : Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chất lượng: ${_weather!.airQuality!.aqiStatus}',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'AQI: ${_weather!.airQuality!.aqi}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Grid of details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAirDetail('PM2.5', '${_weather!.airQuality!.pm2_5.toStringAsFixed(1)}'),
                      _buildAirDetail('PM10', '${_weather!.airQuality!.pm10.toStringAsFixed(1)}'),
                      _buildAirDetail('CO', '${(_weather!.airQuality!.co / 1000).toStringAsFixed(1)}mg'),
                      _buildAirDetail('O₃', '${_weather!.airQuality!.o3.toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 ${_weather!.airQuality!.aqiAdvice}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(210), 
                      fontSize: 11,
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSevere && _weather!.alertMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weather!.alertMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Column(
      children: [
        // Action Bar for Top Quick Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // View Mode Toggle
              OutlinedButton.icon(
                onPressed: () => setState(() => _showMap = !_showMap),
                icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_rounded),
                label: Text(_showMap 
                  ? (widget.isEnglish ? 'View List' : 'Xem danh sách') 
                  : (widget.isEnglish ? 'View Map' : 'Xem bản đồ')
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _refreshLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    tooltip: widget.isEnglish ? 'Refresh Location' : 'Làm mới vị trí',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _sendEmergencyLocation,
                    icon: const Icon(Icons.sos_rounded),
                    label: const Text('SOS'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        _buildWeatherCard(isCompact: !_showMap),
        
        if (!_showMap) ...[
          // Location info card (chỉ hiện ở view danh sách)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      _currentAddress ?? (widget.isEnglish ? 'Your Location' : 'Vị trí của bạn'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentPosition != null
                                ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                : 'Finding GPS...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

          // Search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.isEnglish ? 'Search shelters...' : 'Tìm kiếm nơi trú ẩn...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Nearby shelters section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEnglish
                            ? 'Nearby Emergency Shelters (${_getFilteredShelters().length})'
                            : 'Cơ sở khẩn cấp gần đó (${_getFilteredShelters().length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _getFilteredShelters().isEmpty
                      ? _buildEmptySheltersList()
                      : _buildSheltersList(),
                ),
              ],
            ),
          ),
        ] else ...[
          // Map View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _currentPosition!.latitude, 
                        _currentPosition!.longitude
                      ),
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.trong.meo_sinhton',
                      ),
                      MarkerLayer(
                        markers: [
                          // User Marker
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Shelter Markers - Show all shelters
                          ..._shelters.map((shelter) => Marker(
                            point: LatLng(shelter.latitude, shelter.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showShelterDetails(shelter),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getShelterTypeColor(shelter.type),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getShelterTypeIcon(shelter.type),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          )).toList(),
                        ],
                      ),
                    ],
                  ),
                  // Floating "My Location" Button on Map
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_currentPosition != null) {
                            _mapController.move(
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              15.0
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Info panel at bottom of map
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMapInfoItem(Icons.local_hospital, Colors.red, widget.isEnglish ? 'Hospitals' : 'Bệnh viện'),
                _buildMapInfoItem(Icons.local_police, Colors.blue, widget.isEnglish ? 'Police' : 'Công an'),
                _buildMapInfoItem(Icons.my_location, Colors.green, widget.isEnglish ? 'You' : 'Bạn'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapInfoItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<EmergencyShelter> _getFilteredShelters() {
    if (_searchQuery.isEmpty) {
      return _nearbyShelters;
    }
    
    return _nearbyShelters.where((shelter) =>
        shelter.name.toLowerCase().contains(_searchQuery) ||
        shelter.address.toLowerCase().contains(_searchQuery) ||
        shelter.typeDisplayName.toLowerCase().contains(_searchQuery)
    ).toList();
  }

  Widget _buildEmptySheltersList() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.location_city_outlined,
                size: 50,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // const SizedBox(height: 16),
            // Text(
            //   widget.isEnglish
            //       ? 'No nearby shelters found'
            //       : 'Không tìm thấy cơ sở nào gần đó',
            //   style: Theme.of(context).textTheme.titleLarge,
            //   textAlign: TextAlign.center,
            // ),
            const SizedBox(height: 8),
            Text(
              widget.isEnglish
                  ? 'Try expanding search radius or check GPS settings'
                  : 'Thử mở rộng bán kính tìm kiếm hoặc kiểm tra cài đặt GPS',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _nearbyShelters = _shelters;
                });
              },
              icon: const Icon(Icons.list),
              label: Text(widget.isEnglish ? 'Show All Shelters' : 'Hiển thị tất cả'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSheltersList() {
    final filteredShelters = _getFilteredShelters();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredShelters.length,
      itemBuilder: (context, index) {
        final shelter = filteredShelters[index];
        final distance = _currentPosition != null
            ? EmergencyLocationManager.getDistanceToShelter(shelter, _currentPosition!)
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withAlpha(20)),
          ),
          child: InkWell(
            onTap: () => _showShelterDetails(shelter),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getShelterTypeColor(shelter.type).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getShelterTypeIcon(shelter.type),
                      color: _getShelterTypeColor(shelter.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shelter.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shelter.displayPhone,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Distance & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(distance / 1000).toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (shelter.isAvailable24h)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '24/7',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showShelterDetails(EmergencyShelter shelter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getShelterTypeColor(shelter.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getShelterTypeIcon(shelter.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        shelter.typeDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    Icons.location_on,
                    'Địa chỉ',
                    shelter.address,
                  ),
                  _buildDetailRow(
                    Icons.phone,
                    'Điện thoại',
                    shelter.displayPhone,
                  ),
                  if (shelter.description != null)
                    _buildDetailRow(
                      Icons.info_outline,
                      'Mô tả',
                      shelter.description!,
                    ),
                  if (shelter.isAvailable24h)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Mở cửa 24/7',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(widget.isEnglish ? 'Close' : 'Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                if (shelter.phone.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final phoneUri = Uri(scheme: 'tel', path: shelter.phone);
                        try {
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          }
                        } catch (e) {
                          print('Error making call: $e');
                        }
                      },
                      icon: const Icon(Icons.call),
                      label: Text(widget.isEnglish ? 'Call Now' : 'Gọi ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(160),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getShelterTypeIcon(String type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
        return Icons.local_fire_department;
      default:
        return Icons.location_city;
    }
  }

  Color _getShelterTypeColor(String type) {
    switch (type) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'fire_station':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
