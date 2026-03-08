import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

class PermissionHelper {
  static Future<bool> requestLocationPermission(BuildContext context, bool isEnglish) async {
    try {
      // Check if location permission is already granted
      var status = await permission_handler.Permission.location.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        // Show permission dialog
        bool? shouldRequest = await _showPermissionDialog(
          context,
          isEnglish,
          'location',
        );
        
        if (shouldRequest != true) {
          return false;
        }
        
        // Request permission
        status = await permission_handler.Permission.location.request();
        
        if (status.isGranted) {
          return true;
        }
        
        if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog(context, isEnglish, 'location');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog(context, isEnglish, 'location');
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  static Future<bool> requestSMSPermission(BuildContext context, bool isEnglish) async {
    try {
      var status = await permission_handler.Permission.sms.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        bool? shouldRequest = await _showPermissionDialog(
          context,
          isEnglish,
          'sms',
        );
        
        if (shouldRequest != true) {
          return false;
        }
        
        status = await permission_handler.Permission.sms.request();
        
        if (status.isGranted) {
          return true;
        }
        
        if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog(context, isEnglish, 'sms');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog(context, isEnglish, 'sms');
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error requesting SMS permission: $e');
      return false;
    }
  }

  static Future<bool> requestPhonePermission(BuildContext context, bool isEnglish) async {
    try {
      var status = await permission_handler.Permission.phone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        bool? shouldRequest = await _showPermissionDialog(
          context,
          isEnglish,
          'phone',
        );
        
        if (shouldRequest != true) {
          return false;
        }
        
        status = await permission_handler.Permission.phone.request();
        
        if (status.isGranted) {
          return true;
        }
        
        if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog(context, isEnglish, 'phone');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog(context, isEnglish, 'phone');
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error requesting phone permission: $e');
      return false;
    }
  }

  static Future<bool> requestAllEmergencyPermissions(BuildContext context, bool isEnglish) async {
    return await requestEmergencyPermissionsBatch(context, isEnglish);
  }

  static Future<bool> checkAllPermissions() async {
    final locationStatus = await permission_handler.Permission.location.status;
    final smsStatus = await permission_handler.Permission.sms.status;
    final phoneStatus = await permission_handler.Permission.phone.status;
    
    return locationStatus.isGranted && smsStatus.isGranted && phoneStatus.isGranted;
  }

  static Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }

  static Future<bool> requestEmergencyPermissionsBatch(BuildContext context, bool isEnglish) async {
    try {
      // 1. Check which permissions are still needed
      final statusLocation = await permission_handler.Permission.location.status;
      final statusSms = await permission_handler.Permission.sms.status;
      final statusPhone = await permission_handler.Permission.phone.status;

      List<permission_handler.Permission> permissionsToRequest = [];
      if (!statusLocation.isGranted) permissionsToRequest.add(permission_handler.Permission.location);
      if (!statusSms.isGranted) permissionsToRequest.add(permission_handler.Permission.sms);
      if (!statusPhone.isGranted) permissionsToRequest.add(permission_handler.Permission.phone);

      if (permissionsToRequest.isEmpty) return true;

      // 2. Show ONE consolidated rationale dialog
      bool? shouldRequest = await _showBatchPermissionDialog(context, isEnglish);
      if (shouldRequest != true) return false;

      // 3. Request all in one batch (OS might show sequential dialogs, but we only showed ONE app dialog)
      Map<permission_handler.Permission, permission_handler.PermissionStatus> results = 
          await permissionsToRequest.request();

      // Check if location (minimum requirement for map) is granted
      return results[permission_handler.Permission.location]?.isGranted ?? statusLocation.isGranted;
    } catch (e) {
      print('Error in batch request: $e');
      return false;
    }
  }

  static Future<bool?> _showBatchPermissionDialog(BuildContext context, bool isEnglish) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isEnglish ? 'Emergency Permissions' : 'Quyền cấp cứu khẩn cấp')
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish 
                ? 'To provide emergency features, LifeSpark needs the following permissions:'
                : 'Để cung cấp các tính năng giải cứu, LifeSpark cần các quyền sau đây:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              Icons.location_on, 
              isEnglish ? 'Location' : 'Vị trí',
              isEnglish ? 'Show nearby shelters & Map' : 'Tìm trạm cứu hộ & Bản đồ',
              context
            ),
            _buildPermissionItem(
              Icons.sms, 
              isEnglish ? 'SMS' : 'Tin nhắn SMS',
              isEnglish ? 'Send SOS location to contacts' : 'Gửi vị trí SOS cho người thân',
              context
            ),
            _buildPermissionItem(
              Icons.phone, 
              isEnglish ? 'Phone' : 'Điện thoại',
              isEnglish ? 'Call emergency services directly' : 'Gọi trực tiếp cho cứu thương/CA',
              context
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isEnglish ? 'Grant All' : 'Cấp tất cả'),
          ),
        ],
      ),
    );
  }

  static Widget _buildPermissionItem(IconData icon, String title, String desc, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _showPermissionDialog(
    BuildContext context,
    bool isEnglish,
    String permissionType,
  ) async {
    String title, message, buttonText;
    
    switch (permissionType) {
      case 'location':
        title = isEnglish ? 'Location Permission Required' : 'Cần quyền truy cập vị trí';
        message = isEnglish
            ? 'LifeSpark needs location access to show nearby emergency shelters and send your location in emergencies. This could save your life in critical situations.'
            : 'LifeSpark cần quyền truy cập vị trí để hiển thị các cơ sở khẩn cấp gần đó và gửi vị trí của bạn khi khẩn cấp. Điều này có thể cứu mạng bạn trong tình huống nguy cấp.';
        buttonText = isEnglish ? 'Grant Permission' : 'Cấp quyền';
        break;
      case 'sms':
        title = isEnglish ? 'SMS Permission Required' : 'Cần quyền gửi SMS';
        message = isEnglish
            ? 'LifeSpark needs SMS permission to send your location to emergency contacts when you need help.'
            : 'LifeSpark cần quyền gửi SMS để gửi vị trí của bạn đến người liên lạc khẩn cấp khi bạn cần giúp đỡ.';
        buttonText = isEnglish ? 'Grant Permission' : 'Cấp quyền';
        break;
      case 'phone':
        title = isEnglish ? 'Phone Permission Required' : 'Cần quyền gọi điện';
        message = isEnglish
            ? 'LifeSpark needs phone permission to call emergency services and hospitals directly.'
            : 'LifeSpark cần quyền gọi điện để gọi dịch vụ khẩn cấp và bệnh viện trực tiếp.';
        buttonText = isEnglish ? 'Grant Permission' : 'Cấp quyền';
        break;
      default:
        return false;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPermissionIcon(permissionType),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  static void _showOpenSettingsDialog(
    BuildContext context,
    bool isEnglish,
    String permissionType,
  ) {
    String title, message, settingsText;

    switch (permissionType) {
      case 'location':
        title = isEnglish ? 'Location Permission Denied' : 'Quyền vị trí bị từ chối';
        message = isEnglish
            ? 'Location permission was permanently denied. Please enable it in app settings to use emergency features.'
            : 'Quyền truy cập vị trí đã bị từ chối vĩnh viễn. Vui lòng bật nó trong cài đặt ứng dụng để sử dụng tính năng khẩn cấp.';
        break;
      case 'sms':
        title = isEnglish ? 'SMS Permission Denied' : 'Quyền SMS bị từ chối';
        message = isEnglish
            ? 'SMS permission was permanently denied. Please enable it in app settings to send emergency messages.'
            : 'Quyền gửi SMS đã bị từ chối vĩnh viễn. Vui lòng bật nó trong cài đặt ứng dụng để gửi tin nhắn khẩn cấp.';
        break;
      case 'phone':
        title = isEnglish ? 'Phone Permission Denied' : 'Quyền gọi điện bị từ chối';
        message = isEnglish
            ? 'Phone permission was permanently denied. Please enable it in app settings to call emergency services.'
            : 'Quyền gọi điện đã bị từ chối vĩnh viễn. Vui lòng bật nó trong cài đặt ứng dụng để gọi dịch vụ khẩn cấp.';
        break;
      default:
        return;
    }

    settingsText = isEnglish ? 'Open Settings' : 'Mở Cài đặt';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(settingsText),
          ),
        ],
      ),
    );
  }

  static IconData _getPermissionIcon(String permissionType) {
    switch (permissionType) {
      case 'location':
        return Icons.location_on;
      case 'sms':
        return Icons.sms;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.security;
    }
  }
}
