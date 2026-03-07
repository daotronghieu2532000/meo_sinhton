import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/emergency_location_manager.dart';
import '../models/emergency_shelter.dart';
import '../app/app_strings.dart';
import '../utils/permission_helper.dart';

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
        await _loadShelters();
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

  Future<void> _loadShelters() async {
    if (_currentPosition == null) return;

    try {
      // Load tất cả shelters
      final allShelters = await EmergencyLocationManager.getAllShelters();
      
      // Load nearby shelters (trong bán kính 10km)
      final nearby = await EmergencyLocationManager.findNearbyShelters();

      setState(() {
        _shelters = allShelters;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isEnglish ? 'Send Emergency Location' : 'Gửi vị trí khẩn cấp'),
        content: Text(
          widget.isEnglish
              ? 'Send your current location to emergency contacts?'
              : 'Gửi vị trí hiện tại đến người liên lạc khẩn cấp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
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
                    ),
                  );
                }
              }
            },
            child: Text(widget.isEnglish ? 'Send' : 'Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Emergency Map' : 'Bản đồ Khẩn cấp'),
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshLocation,
              tooltip: widget.isEnglish ? 'Refresh Location' : 'Làm mới vị trí',
            ),
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: _sendEmergencyLocation,
            tooltip: widget.isEnglish ? 'Send SOS' : 'Gửi SOS',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_locationPermissionGranted) {
      return _buildPermissionRequiredScreen();
    }

    if (_currentPosition == null) {
      return _buildLocationErrorScreen();
    }

    return _buildMapContent();
  }

  Widget _buildPermissionRequiredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isEnglish ? 'Location Permission Required' : 'Cần quyền truy cập vị trí',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEnglish
                  ? 'Please enable location access to use emergency features.'
                  : 'Vui lòng bật quyền truy cập vị trí để sử dụng tính năng khẩn cấp.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showLocationPermissionDialog,
              icon: const Icon(Icons.settings),
              label: Text(widget.isEnglish ? 'Enable Location' : 'Bật vị trí'),
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
            Icon(
              Icons.gps_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isEnglish ? 'Location Unavailable' : 'Không thể lấy vị trí',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEnglish
                  ? 'Unable to get your current location. Please check your GPS settings.'
                  : 'Không thể lấy vị trí hiện tại. Vui lòng kiểm tra cài đặt GPS.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh),
              label: Text(widget.isEnglish ? 'Try Again' : 'Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return Column(
      children: [
        // Location info card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.my_location,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEnglish ? 'Your Location' : 'Vị trí của bạn',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _currentPosition != null
                          ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                          : 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Nearby shelters section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.isEnglish
                      ? 'Nearby Emergency Shelters (${_nearbyShelters.length})'
                      : 'Cơ sở khẩn cấp gần đó (${_nearbyShelters.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _nearbyShelters.isEmpty
                    ? _buildEmptySheltersList()
                    : _buildSheltersList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySheltersList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isEnglish
                  ? 'No nearby shelters found'
                  : 'Không tìm thấy cơ sở nào gần đó',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEnglish
                  ? 'Showing all emergency facilities'
                  : 'Hiển thị tất cả cơ sở khẩn cấp',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _nearbyShelters = _shelters;
                });
              },
              child: Text(widget.isEnglish ? 'Show All' : 'Hiển thị tất cả'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheltersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _nearbyShelters.length,
      itemBuilder: (context, index) {
        final shelter = _nearbyShelters[index];
        final distance = _currentPosition != null
            ? EmergencyLocationManager.getDistanceToShelter(shelter, _currentPosition!)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getShelterTypeColor(shelter.type),
              child: Icon(
                _getShelterTypeIcon(shelter.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(shelter.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shelter.address),
                const SizedBox(height: 2),
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(distance / 1000).toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (shelter.isAvailable24h)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '24/7',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => _showShelterDetails(shelter),
          ),
        );
      },
    );
  }

  void _showShelterDetails(EmergencyShelter shelter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shelter.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getShelterTypeIcon(shelter.type),
                  color: _getShelterTypeColor(shelter.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  shelter.typeDisplayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Icon(Icons.location_on, size: 16),
            Text(shelter.address),
            const SizedBox(height: 8),
            Icon(Icons.phone, size: 16),
            Text(shelter.displayPhone),
            if (shelter.description != null) ...[
              const SizedBox(height: 8),
              Icon(Icons.info_outline, size: 16),
              Text(shelter.description!),
            ],
            if (shelter.isAvailable24h) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mở cửa 24/7',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isEnglish ? 'Close' : 'Đóng'),
          ),
          if (shelter.phone.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final phoneUri = Uri(scheme: 'tel', path: shelter.phone);
                try {
                  // Sử dụng url_launcher để gọi điện
                } catch (e) {
                  print('Error making call: $e');
                }
              },
              icon: const Icon(Icons.call),
              label: Text(widget.isEnglish ? 'Call' : 'Gọi'),
            ),
        ],
      ),
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
