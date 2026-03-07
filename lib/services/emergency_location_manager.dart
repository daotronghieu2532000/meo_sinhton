import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_location_data.dart';
import '../models/emergency_shelter.dart';
import 'location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyLocationManager {
  static EmergencyLocationData? _lastKnownLocation;

  // Lưu vị trí khẩn cấp
  static Future<EmergencyLocationData> saveEmergencyLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      throw Exception('Không thể lấy vị trí');
    }

    final address = await LocationService.getAddressFromLocation(position);
    
    final locationData = EmergencyLocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    _lastKnownLocation = locationData;
    return locationData;
  }

  // Lấy vị trí đã lưu lần cuối
  static EmergencyLocationData? getLastKnownLocation() {
    return _lastKnownLocation;
  }

  // Gửi vị trí khẩn cấp qua SMS
  static Future<void> sendEmergencyLocationViaSMS({
    required List<String> emergencyContacts,
    required String message,
  }) async {
    final location = await saveEmergencyLocation();
    
    final locationMessage = '''
$message
${location.locationMessage}
    ''';

    for (String contact in emergencyContacts) {
      final smsUri = Uri(
        scheme: 'sms',
        path: contact,
        queryParameters: {'body': locationMessage},
      );

      try {
        await launchUrl(smsUri);
      } catch (e) {
        print('Error sending SMS to $contact: $e');
      }
    }
  }

  // Chia sẻ vị trí qua các app khác
  static Future<void> shareEmergencyLocation({
    required String message,
  }) async {
    final location = await saveEmergencyLocation();
    
    final shareText = '''
$message
${location.locationMessage}
    ''';

    final shareUri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send',
      queryParameters: {'text': shareText},
    );

    try {
      await launchUrl(shareUri);
    } catch (e) {
      print('Error sharing location: $e');
    }
  }

  // Tìm nơi trú ẩn gần nhất (Sử dụng Overpass API để lấy dữ liệu thực tế xung quanh)
  static Future<List<EmergencyShelter>> findNearbyShelters({
    double radiusKm = 5.0,
  }) async {
    final position = await LocationService.getCurrentLocation();
    if (position == null) return [];

    try {
      // 1. Lấy dữ liệu thực tế từ OpenStreetMap qua Overpass API
      final dynamicData = await _fetchNearbyFromOSM(
        position.latitude, 
        position.longitude, 
        radiusKm * 1000
      );

      // 2. Lấy dữ liệu mẫu (hoặc dữ liệu riêng của app) 
      final sampleData = await _getSheltersFromDatabase();
      
      // 3. Kết hợp và lọc theo bán kính
      final combined = [...dynamicData, ...sampleData];
      
      final nearbyShelters = combined.where((shelter) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shelter.latitude,
          shelter.longitude,
        );
        return distance <= (radiusKm * 1000);
      }).toList();

      // Sắp xếp theo khoảng cách
      nearbyShelters.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          position.latitude, position.longitude, a.latitude, a.longitude);
        final distB = Geolocator.distanceBetween(
          position.latitude, position.longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      return nearbyShelters;
    } catch (e) {
      print('Error finding nearby shelters: $e');
      // Fallback về dữ liệu mẫu nếu API lỗi
      return await _getSheltersFromDatabase();
    }
  }

  // Lấy dữ liệu thực tế từ OpenStreetMap
  static Future<List<EmergencyShelter>> _fetchNearbyFromOSM(double lat, double lon, double radius) async {
    // Tối ưu query: chỉ lấy node và way trung tâm, giảm timeout xuống 10s
    final query = '''
    [out:json][timeout:10];
    (
      node["amenity"~"hospital|police|fire_station|clinic"](around:$radius,$lat,$lon);
      way["amenity"~"hospital|police|fire_station|clinic"](around:$radius,$lat,$lon);
    );
    out center;
    ''';
    
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    try {
      final response = await http.post(url, body: query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        
        return elements.map((e) {
          final tags = e['tags'] ?? {};
          final type = tags['amenity'] == 'police' ? 'police' : 'hospital';
          final latVal = e['lat'] ?? e['center']?['lat'];
          final lonVal = e['lon'] ?? e['center']?['lon'];
          
          return EmergencyShelter(
            id: 'osm_${e['id']}',
            name: tags['name'] ?? (tags['amenity'] == 'police' ? 'Đồn Công an' : 'Cơ sở Y tế'),
            address: tags['addr:full'] ?? tags['addr:street'] ?? 'Địa chỉ đang cập nhật',
            latitude: latVal.toDouble(),
            longitude: lonVal.toDouble(),
            type: type,
            phone: tags['phone'] ?? tags['contact:phone'] ?? '',
            description: tags['operator'] ?? 'Dữ liệu từ cộng đồng',
            isAvailable24h: tags['opening_hours'] == '24/7',
          );
        }).toList();
      }
    } catch (e) {
      print('OSM Fetch Error: $e');
    }
    return [];
  }

  // Tính khoảng cách đến nơi trú ẩn
  static double getDistanceToShelter(
    EmergencyShelter shelter,
    Position userPosition,
  ) {
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      shelter.latitude,
      shelter.longitude,
    );
  }

  // Lấy danh sách nơi trú ẩn từ database
  static Future<List<EmergencyShelter>> _getSheltersFromDatabase() async {
    // Database các nơi trú ẩn tại Việt Nam
    return [
      // Hà Nội
      EmergencyShelter(
        id: 'bv_bach_mai',
        name: 'Bệnh viện Bạch Mai',
        address: '78 Giải Phóng, Đống Đa, Hà Nội',
        latitude: 21.0045,
        longitude: 105.8565,
        type: 'hospital',
        phone: '024.3869.3000',
        description: 'Bệnh viện đa khoa tuyến cuối',
        isAvailable24h: true,
      ),
      EmergencyShelter(
        id: 'bv_viet_duc',
        name: 'Bệnh viện Việt Đức',
        address: '40 Tràng Thi, Hoàn Kiếm, Hà Nội',
        latitude: 21.0288,
        longitude: 105.8520,
        type: 'hospital',
        phone: '024.3825.3535',
        description: 'Bệnh viện đa khoa',
        isAvailable24h: true,
      ),
      EmergencyShelter(
        id: 'ca_hoan_kiem',
        name: 'Công an quận Hoàn Kiếm',
        address: '19 Hàng Bài, Hoàn Kiếm, Hà Nội',
        latitude: 21.0285,
        longitude: 105.8525,
        type: 'police',
        phone: '024.3825.2525',
        description: 'Đội cảnh sát khu vực',
        isAvailable24h: true,
      ),
      
      // TP.HCM
      EmergencyShelter(
        id: 'bv_cho_ray',
        name: 'Bệnh viện Chợ Rẫy',
        address: '201B Nguyễn Chí Thanh, Quận 5, TP.HCM',
        latitude: 10.7769,
        longitude: 106.6800,
        type: 'hospital',
        phone: '028.3956.4133',
        description: 'Bệnh viện đa khoa tuyến cuối',
        isAvailable24h: true,
      ),
      EmergencyShelter(
        id: 'bv_thu_duc',
        name: 'Bệnh viện Thú Duc',
        address: '286 Trần Xuân Soạn, TP. Thủ Đức, TP.HCM',
        latitude: 10.8482,
        longitude: 106.7312,
        type: 'hospital',
        phone: '028.3865.2500',
        description: 'Bệnh viện đa khoa',
        isAvailable24h: true,
      ),
      EmergencyShelter(
        id: 'ca_quan_1',
        name: 'Công an Quận 1',
        address: '161 Lê Thánh Tôn, Quận 1, TP.HCM',
        latitude: 10.7796,
        longitude: 106.6987,
        type: 'police',
        phone: '028.3839.8255',
        description: 'Công an quận',
        isAvailable24h: true,
      ),
      
      // Đà Nẵng
      EmergencyShelter(
        id: 'bv_c_da_nang',
        name: 'Bệnh viện C Đà Nẵng',
        address: '122 Hải Phòng, Thanh Khê, Đà Nẵng',
        latitude: 16.0667,
        longitude: 108.2167,
        type: 'hospital',
        phone: '0236.3823.3333',
        description: 'Bệnh viện đa khoa',
        isAvailable24h: true,
      ),
      EmergencyShelter(
        id: 'ca_hai_chau',
        name: 'Công an quận Hải Châu',
        address: '23 Trần Phú, Hải Châu, Đà Nẵng',
        latitude: 16.0665,
        longitude: 108.2169,
        type: 'police',
        phone: '0236.3822.8255',
        description: 'Công an quận',
        isAvailable24h: true,
      ),
      
      // Huế
      EmergencyShelter(
        id: 'bv_central_hue',
        name: 'Bệnh viện Trung ương Huế',
        address: '16 Lê Lợi, Phú Hội, TP. Huế',
        latitude: 16.4635,
        longitude: 107.5909,
        type: 'hospital',
        phone: '0234.3822.2222',
        description: 'Bệnh viện đa khoa tuyến cuối',
        isAvailable24h: true,
      ),
      
      // Nha Trang
      EmergencyShelter(
        id: 'bv_khanh_hoa',
        name: 'Bệnh viện Đa khoa Khánh Hòa',
        address: '46 Yersin, Lộc Thọ, Nha Trang',
        latitude: 12.2389,
        longitude: 109.1967,
        type: 'hospital',
        phone: '0258.3822.2222',
        description: 'Bệnh viện đa khoa tỉnh',
        isAvailable24h: true,
      ),
    ];
  }

  // Lấy tất cả nơi trú ẩn (cho map view)
  static Future<List<EmergencyShelter>> getAllShelters() async {
    return await _getSheltersFromDatabase();
  }
}
