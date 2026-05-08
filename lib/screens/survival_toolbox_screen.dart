import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'package:meo_sinhton/screens/emergency_profile_screen.dart';

class SurvivalToolboxScreen extends StatefulWidget {
  final AppController appController;

  const SurvivalToolboxScreen({super.key, required this.appController});

  @override
  State<SurvivalToolboxScreen> createState() => _SurvivalToolboxScreenState();
}

class _SurvivalToolboxScreenState extends State<SurvivalToolboxScreen> {
  bool _isTorchAvailable = false;
  bool _isTorchOn = false;
  bool _isSOSRunning = false;
  Timer? _sosTimer;
  double? _heading = 0;
  
  // For CPR Metronome
  bool _isCPRRunning = false;
  Timer? _cprTimer;
  double _pulseScale = 1.0;

  // For Pedometer/Step Counter (using accelerometer as fallback)
  int _stepCount = 0;
  StreamSubscription? _accelerometerSub;
  double _lastMagnitude = 0;
  
  // For Spirit Level
  double _levelX = 0;
  double _levelY = 0;

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
    _checkTorchAvailability();
    _initCompass();
    _initPedometer();
  }

  Future<void> _checkTorchAvailability() async {
    try {
      final isAvailable = await TorchLight.isTorchAvailable();
      setState(() => _isTorchAvailable = isAvailable);
    } catch (e) {
      setState(() => _isTorchAvailable = false);
    }
  }

  void _initCompass() {
    FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() => _heading = event.heading);
      }
    });
  }

  void _initPedometer() {
    _accelerometerSub = accelerometerEventStream().listen((event) {
      double magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mounted) {
        setState(() {
          _levelX = event.x;
          _levelY = event.y;
          
          if (_lastMagnitude > 12 && magnitude < 10) {
            _stepCount++;
          }
        });
      }
      _lastMagnitude = magnitude;
    });
  }

  Future<void> _toggleTorch() async {
    if (!_isTorchAvailable) return;
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error controlling flashlight')));
    }
  }

  void _toggleSOS() {
    if (_isSOSRunning) {
      _sosTimer?.cancel();
      TorchLight.disableTorch();
      setState(() {
        _isSOSRunning = false;
        _isTorchOn = false;
      });
    } else {
      setState(() => _isSOSRunning = true);
      _runMorseSOS();
    }
  }

  Future<void> _runMorseSOS() async {
    // SOS: . . . | - - - | . . .
    const dot = Duration(milliseconds: 200);
    const dash = Duration(milliseconds: 600);
    const space = Duration(milliseconds: 200);

    while (_isSOSRunning) {
      for (int i = 0; i < 3; i++) {
        if (!_isSOSRunning) break;
        await TorchLight.enableTorch();
        await Future.delayed(dot);
        await TorchLight.disableTorch();
        await Future.delayed(space);
      }
      await Future.delayed(dash);
      for (int i = 0; i < 3; i++) {
        if (!_isSOSRunning) break;
        await TorchLight.enableTorch();
        await Future.delayed(dash);
        await TorchLight.disableTorch();
        await Future.delayed(space);
      }
      await Future.delayed(dash);
      for (int i = 0; i < 3; i++) {
        if (!_isSOSRunning) break;
        await TorchLight.enableTorch();
        await Future.delayed(dot);
        await TorchLight.disableTorch();
        await Future.delayed(space);
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void _toggleCPR() {
    if (_isCPRRunning) {
      _cprTimer?.cancel();
      setState(() {
        _isCPRRunning = false;
        _pulseScale = 1.0;
      });
    } else {
      setState(() => _isCPRRunning = true);
      // 110 BPM = 60 / 110 = ~0.545 seconds = 545ms
      _cprTimer = Timer.periodic(const Duration(milliseconds: 545), (timer) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _pulseScale = 1.2;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => _pulseScale = 1.0);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _accelerometerSub?.cancel();
    _cprTimer?.cancel();
    TorchLight.disableTorch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('Công cụ sinh tồn', 'Survival Toolbox', 'Narzędzia survivalowe')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(scheme),
            const SizedBox(height: 16),
            _buildCompassCard(scheme),
            const SizedBox(height: 16),
            _buildLevelCard(scheme),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildToolCard(
                  icon: _isSOSRunning ? Icons.sos : Icons.flashlight_on_rounded,
                  title: _tr('Đèn pin SOS', 'SOS Flashlight', 'Latarka SOS'),
                  color: _isSOSRunning ? Colors.red : (_isTorchOn ? Colors.amber : scheme.primary),
                  onTap: _isSOSRunning ? _toggleSOS : _toggleTorch,
                  isActive: _isTorchOn || _isSOSRunning,
                  subtitle: _isSOSRunning ? 'SENDING SOS...' : (_isTorchOn ? 'ON' : 'OFF'),
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildToolCard(
                  icon: Icons.directions_walk,
                  title: _tr('Đếm bước chân', 'Step Counter', 'Licznik kroków'),
                  color: Colors.green,
                  onTap: () => setState(() => _stepCount = 0),
                  subtitle: '$_stepCount steps',
                  isActive: _stepCount > 0,
                )),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetronomeCard(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassCard(ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _tr('La bàn kỹ thuật số', 'Digital Compass', 'Kompas cyfrowy'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Transform.rotate(
              angle: ((_heading ?? 0) * (math.pi / 180) * -1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.compass_calibration_outlined, size: 200, color: scheme.primary.withOpacity(0.1)),
                  const Icon(Icons.navigation, size: 40, color: Colors.red),
                  ...List.generate(4, (index) {
                    final labels = ['N', 'E', 'S', 'W'];
                    return Transform.rotate(
                      angle: (index * 90) * (math.pi / 180),
                      child: Container(
                        height: 180,
                        alignment: Alignment.topCenter,
                        child: Text(labels[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_heading?.toStringAsFixed(0) ?? '0'}°',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required String subtitle,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: isActive ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isActive ? color : Colors.transparent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetronomeCard(ColorScheme scheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      transform: Matrix4.diagonal3Values(_isCPRRunning ? _pulseScale : 1.0, _isCPRRunning ? _pulseScale : 1.0, 1.0),
      transformAlignment: Alignment.center,
      child: Card(
        elevation: 0,
        color: _isCPRRunning ? Colors.blue.withOpacity(0.1) : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _isCPRRunning ? Colors.blue : Colors.transparent, width: 2),
        ),
        child: ListTile(
          leading: Icon(
            _isCPRRunning ? Icons.favorite : Icons.favorite_border,
            color: _isCPRRunning ? Colors.red : Colors.blue,
            size: 32,
          ),
          title: Text(
            _tr('Nhịp hồi sức tim phổi (CPR)', 'CPR Metronome', 'Metronom CPR'),
            style: TextStyle(fontWeight: _isCPRRunning ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            _isCPRRunning
                ? _tr('ĐANG CHẠY: 110 Nhịp/phút', 'RUNNING: 110 BPM', 'DZIAŁA: 110 BPM')
                : _tr('Duy trì 100-120 nhịp/phút', 'Maintain 100-120 BPM', 'Utrzymuj 100-120 BPM'),
          ),
          trailing: Icon(
            _isCPRRunning ? Icons.stop_circle : Icons.play_circle_fill,
            color: _isCPRRunning ? Colors.red : Colors.blue,
            size: 32,
          ),
          onTap: _toggleCPR,
        ),
      ),
    );
  }

  Widget _buildProfileSection(ColorScheme scheme) {
    final hasProfile = widget.appController.emergencyName.isNotEmpty;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmergencyProfileScreen(appController: widget.appController)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.errorContainer, scheme.onErrorContainer.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.error,
              radius: 24,
              child: const Icon(Icons.emergency_share, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Hồ sơ khẩn cấp', 'Emergency Profile', 'Profil alarmowy'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.error),
                  ),
                  Text(
                    hasProfile 
                      ? widget.appController.emergencyName 
                      : _tr('Chưa thiết lập thông tin', 'Not set up yet', 'Nie ustawiono'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(ColorScheme scheme) {
    // Clamp values to a reasonable range for visualization
    final double normX = (_levelX / 10).clamp(-1.0, 1.0);
    final double normY = (_levelY / 10).clamp(-1.0, 1.0);
    final bool isLevel = normX.abs() < 0.05 && normY.abs() < 0.05;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.architecture, color: scheme.secondary),
                const SizedBox(width: 12),
                Text(
                  _tr('Thước thủy cân bằng', 'Spirit Level', 'Poziomica'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isLevel) const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center circle target
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outline, width: 1),
                    ),
                  ),
                  // Moving bubble
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 50),
                    alignment: Alignment(normX, normY),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isLevel ? Colors.green : scheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: (isLevel ? Colors.green : scheme.secondary).withOpacity(0.3), blurRadius: 8),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'X: ${_levelX.toStringAsFixed(1)}°  Y: ${_levelY.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
