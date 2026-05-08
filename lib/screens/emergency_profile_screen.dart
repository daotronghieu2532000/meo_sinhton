import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';

class EmergencyProfileScreen extends StatefulWidget {
  final AppController appController;

  const EmergencyProfileScreen({super.key, required this.appController});

  @override
  State<EmergencyProfileScreen> createState() => _EmergencyProfileScreenState();
}

class _EmergencyProfileScreenState extends State<EmergencyProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _medicalController;

  String _tr(String vi, String en, String pl) {
    switch (widget.appController.language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.polish:
        return pl;
      case AppLanguage.vietnamese:
        return vi;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.appController.emergencyName);
    _phoneController = TextEditingController(text: widget.appController.emergencyPhone);
    _bloodTypeController = TextEditingController(text: widget.appController.emergencyBloodType);
    _medicalController = TextEditingController(text: widget.appController.emergencyMedical);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await widget.appController.updateEmergencyProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodType: _bloodTypeController.text.trim(),
      medical: _medicalController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Đã lưu thông tin!', 'Profile saved!', 'Profil zapisany!'))),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('Hồ sơ khẩn cấp', 'Emergency Profile', 'Profil alarmowy')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
            tooltip: _tr('Lưu', 'Save', 'Zapisz'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _tr(
                        'Thông tin này sẽ được lưu trên máy của bạn và giúp ích trong trường hợp khẩn cấp.',
                        'This information is stored locally on your device and helps in emergencies.',
                        'Te informacje są przechowywane lokalnie i pomagają w sytuacjach awaryjnych.',
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: _tr('Họ và tên', 'Full Name', 'Imię i nazwisko'),
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: _tr('SĐT Liên hệ khẩn cấp', 'Emergency Contact', 'Kontakt alarmowy'),
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _bloodTypeController,
              label: _tr('Nhóm máu', 'Blood Type', 'Grupa krwi'),
              icon: Icons.bloodtype_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _medicalController,
              label: _tr('Lưu ý y tế (Dị ứng, bệnh lý...)', 'Medical Notes (Allergies, conditions...)', 'Uwagi medyczne'),
              icon: Icons.medical_services_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _tr('Lưu hồ sơ', 'Save Profile', 'Zapisz profil'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }
}
