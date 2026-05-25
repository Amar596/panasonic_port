import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:panasonic_port/services/wauly_app_service.dart';
import 'package:panasonic_port/wauly_monitor_screen.dart';
import 'package:panasonic_port/widgets/storage_info_widget.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:panasonic_port/Port_Control.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monitoring_model.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int? _hdmiStatus;
  int? _currentVolume;
  bool _hdmiMode = false;
  int currentAngle = 0;
  bool _isLoading = false;
  int _currentBrightness = 50;
  bool _isChecking = false;
  String _statusMessage = '';
  String _statusDetails = '';

  String? _macAddress;
  String? _deviceId;
  String? _serialNumber;
  String? _clientType;
  String? _appId;
  String _appVersion = '';
  String _currentDateTime = '';
  bool _autoOpenEnabled = true;
  bool _isOpeningApp = false;

  static const String KEY_AUTO_OPEN_ENABLED = 'auto_open_wauly_enabled';

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentBrightness();
    _initConnectivity();
    _listenForConnectivityChanges();
    _autoClickOpenWaulyApp();
  }

  // Add this method to save setting
  Future<void> _saveAutoOpenSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_AUTO_OPEN_ENABLED, value);
    print('💾 Auto-open setting saved: $value');
  }

  // Show status overlay
  void _showStatusOverlay(
      {required bool show, String? message, String? details}) {
    setState(() {
      _isChecking = show;
      _statusMessage = message ?? '';
      _statusDetails = details ?? '';
    });
  }

  Future<void> _autoClickOpenWaulyApp() async {
    // ✅ HARD STOP
    if (!_autoOpenEnabled) {
      print('⛔ Auto-open disabled — skipping execution');
      return;
    }

    if (_isOpeningApp) {
      print('⏸️ Already opening Wauly app, skipping...');
      return;
    }

    _isOpeningApp = true;

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted && _autoOpenEnabled) {
      print('🤖 Auto-clicking Open Wauly App button (homepage active)');
      await WaulyAppManager.handleAppFlow(context);
    }

    _isOpeningApp = false;
  }

  Future<void> _checkAppUpdate() async {
    _showStatusOverlay(
      show: true,
      message: 'Checking for updates...',
      details: 'Connecting to ${WaulyAppManager.versionUrl}',
    );

    try {
      await WaulyAppManager.handleAppFlow(context);
    } catch (e) {
      _showStatusOverlay(
        show: true,
        message: 'Update check failed',
        details: e.toString(),
      );
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      if (mounted) {
        _showStatusOverlay(show: false);
      }
    }
  }

  Future<void> _showQuickUrlDialog() async {
    // Get current URLs
    final currentVersionUrl = WaulyAppManager.versionUrl;
    final currentApkUrl = WaulyAppManager.apkUrl;

    final versionController = TextEditingController(text: currentVersionUrl);
    final apkController = TextEditingController(text: currentApkUrl);

    final shouldUseAzure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Configure Update URLs',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version XML URL:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: versionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://.../version.xml',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
                prefixIcon: const Icon(Icons.link, color: Colors.greenAccent),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            const Text(
              'APK Download URL:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://.../app.apk',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
                prefixIcon:
                    const Icon(Icons.cloud_download, color: Colors.greenAccent),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_queue,
                      color: Colors.blue.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Azure Default',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'https://waulymvcapp.blob.core.windows.net/waulymvcdev/Builds/Android/Host/version.xml',
                          style: TextStyle(
                              color: Colors.blue.shade300, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final versionUrl = versionController.text.trim();
              final apkUrl = apkController.text.trim();

              if (versionUrl.isNotEmpty && apkUrl.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                // Show error if URLs are empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter both URLs'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldUseAzure == true) {
      // Build URLs from the text fields
      final versionUrl = versionController.text.trim();
      final apkUrl = apkController.text.trim();

      // Update URLs
      WaulyAppManager.versionUrl = versionUrl;
      WaulyAppManager.apkUrl = apkUrl;

      // Save to SharedPreferences if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(WaulyAppManager.KEY_CUSTOM_VERSION_URL, versionUrl);
      await prefs.setString(WaulyAppManager.KEY_CUSTOM_APK_URL, apkUrl);

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom URLs saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Test connection
      await _testConnection();

      // Refresh the UI
      setState(() {});
    }
  }

  // Test connection with status
  Future<void> _testConnection() async {
    _showStatusOverlay(
      show: true,
      message: 'Testing connection...',
      details: 'Connecting to ${WaulyAppManager.versionUrl}',
    );

    try {
      final versionInfo = await WaulyAppManager.fetchLatestVersion();
      if (versionInfo != null) {
        _showStatusOverlay(
          show: true,
          message: 'Connection successful!',
          details: 'Latest version: ${versionInfo.version}',
        );
      } else {
        _showStatusOverlay(
          show: true,
          message: 'Connection failed',
          details: 'Could not fetch version info',
        );
      }
    } catch (e) {
      _showStatusOverlay(
        show: true,
        message: 'Connection failed',
        details: e.toString(),
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      _showStatusOverlay(show: false);
    }
  }

  // Initialize connectivity status
  Future<void> _initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      print('Couldn\'t check connectivity status: $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    _updateConnectionStatus(result);
  }

  // Listen for connectivity changes
  void _listenForConnectivityChanges() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Update connection status
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _connectionStatus = result;
    });
  }

  // Get connection status text
  String get _connectionStatusText {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'Connected to WiFi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected to Ethernet';
      case ConnectivityResult.vpn:
        return 'Connected via VPN';
      case ConnectivityResult.bluetooth:
        return 'Connected via Bluetooth';
      case ConnectivityResult.other:
        return 'Connected (Other)';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Status';
    }
  }

  // Get connection status color
  Color get _connectionStatusColor {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return Colors.green; // Connected
      case ConnectivityResult.none:
        return Colors.red; // Disconnected
      default:
        return Colors.orange; // Other/Unknown
    }
  }

  // Get connection icon
  IconData get _connectionStatusIcon {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      case ConnectivityResult.vpn:
        return Icons.security;
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.none:
        return Icons.signal_wifi_off;
      default:
        return Icons.network_check;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentBrightness() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  _connectionStatusIcon,
                  color: _connectionStatusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectionStatus == ConnectivityResult.wifi ||
                          _connectionStatus == ConnectivityResult.mobile ||
                          _connectionStatus == ConnectivityResult.ethernet
                      ? 'Online'
                      : 'Offline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _connectionStatusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact connectivity status bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _connectionStatus == ConnectivityResult.none
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              border: Border(
                bottom: BorderSide(
                  color: _connectionStatusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _connectionStatusIcon,
                  color: _connectionStatusColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internet Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        _connectionStatusText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _connectionStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _initConnectivity,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 246, 246, 247),
              borderRadius: BorderRadius.circular(1),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Signage App Status',
                      style: TextStyle(
                        color: Color.fromARGB(255, 91, 14, 226),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Version: $_appVersion',
                  style: const TextStyle(
                      color: Color.fromARGB(255, 91, 14, 226), fontSize: 13),
                ),
                const SizedBox(height: 1),
                Text(
                  'Time: $_currentDateTime',
                  style: const TextStyle(
                      color: Color.fromARGB(255, 91, 14, 226), fontSize: 13),
                ),
              ],
            ),
          ),

          const StorageInfoWidget(), 
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _autoOpenEnabled
                    ? [
                        Colors.green.shade900.withOpacity(0.3),
                        const Color(0xFF161B22)
                      ]
                    : [
                        Colors.grey.shade900.withOpacity(0.3),
                        const Color(0xFF161B22)
                      ],
              ),
              borderRadius: BorderRadius.circular(1),
              border: Border.all(
                color: _autoOpenEnabled
                    ? Colors.greenAccent
                    : Colors.grey.shade700,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _autoOpenEnabled ? Icons.touch_app : Icons.block,
                  color: _autoOpenEnabled ? Colors.greenAccent : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _autoOpenEnabled
                        ? 'Signage App - Auto launch ENABLED'
                        : 'Signage App - Auto launch DISABLED',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Switch(
                  value: _autoOpenEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _autoOpenEnabled = value;
                    });
                    await _saveAutoOpenSetting(value);

                    if (value) {
                      // Optional: trigger once immediately when turned ON
                      _autoClickOpenWaulyApp();
                    }
                  },
                ),
              ],
            ),
          ),

          // Compact buttons grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // System Control Section
                  _buildSectionTitle('System Control'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCompactButton(
                        'Shutdown',
                        Icons.power_settings_new,
                        () => PortControl.shutDown(),
                      ),
                      _buildCompactButton(
                        'Reboot',
                        Icons.restart_alt,
                        () => PortControl.reboot(),
                      ),
                      _buildCompactButton(
                        'Turn Off',
                        Icons.power_off,
                        () => PortControl.turnOff(),
                      ),
                      _buildCompactButton(
                        'Rotate',
                        Icons.rotate_right,
                        () {
                          const angles = [0, 90, 180, 270];
                          setState(() {
                            currentAngle = angles[
                                (angles.indexOf(currentAngle) + 1) %
                                    angles.length];
                          });
                          PortControl.setDisplayOrientation(currentAngle);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // HDMI Control Section
                  _buildSectionTitle('HDMI Control'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCompactButton(
                        'Open HDMI',
                        Icons.video_settings,
                        () => PortControl.openHdmi(1),
                      ),
                      _buildCompactButton(
                        'Close HDMI',
                        Icons.videocam_off,
                        () => PortControl.closeHdmi(),
                      ),
                      _buildCompactButton(
                        'HDMI Status',
                        Icons.info,
                        () async {
                          final status = await PortControl.getHdmiStatus(1);
                          setState(() => _hdmiStatus = status);
                        },
                      ),
                    ],
                  ),
                  if (_hdmiStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'HDMI Status: $_hdmiStatus',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Display Control Section
                  _buildSectionTitle('Display Control'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...['25%', '50%', '75%', '100%'].map((label) {
                        final value = int.parse(label.replaceAll('%', ''));
                        return _buildCompactButton(
                          label,
                          Icons.brightness_6,
                          () {
                            PortControl.setBackLight(value);
                            setState(() => _currentBrightness = value);
                          },
                          isSelected: _currentBrightness == value,
                        );
                      }),
                      // _buildCompactButton(
                      //   'Capture',
                      //   Icons.camera,
                      //   () async {
                      //     final dir = await getExternalStorageDirectory();
                      //     final filePath =
                      //         "${dir!.path}/Pictures/screen_cap_1.jpg";
                      //     await PortControl.startScreenCap(filePath);
                      //   },
                      // ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Audio Control Section
                  _buildSectionTitle('Audio Control'),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: (_currentVolume ?? 50).toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 10,
                              onChanged: (value) async {
                                await PortControl.setSystemVoice(value.toInt());
                                setState(() => _currentVolume = value.toInt());
                              },
                            ),
                          ),
                          Text(
                            '${_currentVolume ?? 50}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactButton(
                            'Mute',
                            Icons.volume_off,
                            () {
                              PortControl.mute();
                              setState(() => _currentVolume = 0);
                            },
                          ),
                          _buildCompactButton(
                            'Unmute',
                            Icons.volume_up,
                            () async {
                              await PortControl.unMute();
                              final volume = await PortControl.getSystemVoice();
                              setState(() => _currentVolume = volume);
                            },
                          ),
                          _buildCompactButton(
                            'Get Vol',
                            Icons.volume_down,
                            () async {
                              final volume = await PortControl.getSystemVoice();
                              setState(() => _currentVolume = volume);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Device Info Section
                  _buildSectionTitle('Device Info'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCompactButton(
                        'MAC',
                        Icons.device_hub,
                        () async {
                          final mac = await PortControl.getMacAddress();
                          setState(() => _macAddress = mac);
                        },
                      ),
                      _buildCompactButton(
                        'Device ID',
                        Icons.devices,
                        () async {
                          final id = await PortControl.getDeviceId();
                          setState(() => _deviceId = id);
                        },
                      ),
                      _buildCompactButton(
                        'Serial',
                        Icons.numbers,
                        () async {
                          try {
                            final sn = await PortControl.getSN();
                            setState(
                                () => _serialNumber = sn ?? 'Not available');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        },
                      ),
                      _buildCompactButton(
                        'Client Type',
                        Icons.public,
                        () async {
                          final type = await PortControl.getClientType();
                          setState(() => _clientType = type);
                        },
                      ),
                      _buildCompactButton(
                        'App ID',
                        Icons.apps,
                        () async {
                          final appId = await PortControl.getAppId();
                          setState(() => _appId = appId);
                        },
                      ),
                    ],
                  ),

                  // Display device info
                  if (_macAddress != null ||
                      _deviceId != null ||
                      _serialNumber != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_macAddress != null)
                            _buildInfoRow('MAC:', _macAddress!),
                          if (_deviceId != null)
                            _buildInfoRow('Device ID:', _deviceId!),
                          if (_serialNumber != null)
                            _buildInfoRow('SN:', _serialNumber!),
                          if (_clientType != null)
                            _buildInfoRow('Client Type:', _clientType!),
                          if (_appId != null) _buildInfoRow('App ID:', _appId!),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  //App Launcher Section
                  _buildSectionTitle('Applications'),
                  _buildCompactButton(
                    'Wauly',
                    Icons.open_in_new,
                    () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        await WaulyAppManager.handleAppFlow(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        // Close loading dialog if still open
                        if (context.mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCompactButton(
                    'Event Monitor',
                    Icons.monitor_heart,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WaulyMonitorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildCompactButton(String text, IconData icon, VoidCallback onPressed,
      {bool isSelected = false}) {
    return Container(
      width: 100, // Fixed width for consistent sizing
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          backgroundColor: isSelected ? Colors.blue.shade100 : null,
          foregroundColor: isSelected ? Colors.blue.shade800 : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: value == 'Not available'
                    ? Colors.red
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
