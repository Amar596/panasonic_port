// import 'package:external_app_launcher/external_app_launcher.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:panasonic_port/Port_Control.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:async';

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int? _hdmiStatus;
//   int? _currentVolume;
//   bool _hdmiMode = false;
//   int currentAngle = 0;
//   bool _isLoading = false;
//   int _currentBrightness = 50;

//   String? _macAddress;
//   String? _deviceId;
//   String? _serialNumber;
//   String? _clientType;
//   String? _appId;

//   ConnectivityResult _connectionStatus = ConnectivityResult.none;
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentBrightness();
//      _initConnectivity();
//     _listenForConnectivityChanges();
//   }

//   // Initialize connectivity status
//   Future<void> _initConnectivity() async {
//     late ConnectivityResult result;
//     try {
//       result = await _connectivity.checkConnectivity();
//     } catch (e) {
//       print('Couldn\'t check connectivity status: $e');
//       return;
//     }

//     if (!mounted) {
//       return Future.value(null);
//     }

//     _updateConnectionStatus(result);
//   }

//   // Listen for connectivity changes
//   void _listenForConnectivityChanges() {
//     _connectivitySubscription =
//         _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//   }

//   // Update connection status
//   void _updateConnectionStatus(ConnectivityResult result) {
//     setState(() {
//       _connectionStatus = result;
//     });
//   }

//    // Get connection status text
//   String get _connectionStatusText {
//     switch (_connectionStatus) {
//       case ConnectivityResult.wifi:
//         return 'Connected to WiFi';
//       case ConnectivityResult.mobile:
//         return 'Connected to Mobile Data';
//       case ConnectivityResult.ethernet:
//         return 'Connected to Ethernet';
//       case ConnectivityResult.vpn:
//         return 'Connected via VPN';
//       case ConnectivityResult.bluetooth:
//         return 'Connected via Bluetooth';
//       case ConnectivityResult.other:
//         return 'Connected (Other)';
//       case ConnectivityResult.none:
//         return 'No Internet Connection';
//       default:
//         return 'Unknown Status';
//     }
//   }

//   // Get connection status color
//   Color get _connectionStatusColor {
//     switch (_connectionStatus) {
//       case ConnectivityResult.wifi:
//       case ConnectivityResult.mobile:
//       case ConnectivityResult.ethernet:
//         return Colors.green; // Connected
//       case ConnectivityResult.none:
//         return Colors.red; // Disconnected
//       default:
//         return Colors.orange; // Other/Unknown
//     }
//   }

//   // Get connection icon
//   IconData get _connectionStatusIcon {
//     switch (_connectionStatus) {
//       case ConnectivityResult.wifi:
//         return Icons.wifi;
//       case ConnectivityResult.mobile:
//         return Icons.signal_cellular_4_bar;
//       case ConnectivityResult.ethernet:
//         return Icons.settings_ethernet;
//       case ConnectivityResult.vpn:
//         return Icons.security;
//       case ConnectivityResult.bluetooth:
//         return Icons.bluetooth;
//       case ConnectivityResult.none:
//         return Icons.signal_wifi_off;
//       default:
//         return Icons.network_check;
//     }
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription.cancel(); // Cancel subscription
//     super.dispose();
//   }

//   Future<void> _loadCurrentBrightness() async {
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//           actions: [
//           // Add connectivity indicator in app bar
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Row(
//               children: [
//                 Icon(
//                   _connectionStatusIcon,
//                   color: _connectionStatusColor,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _connectionStatus == ConnectivityResult.wifi ||
//                           _connectionStatus == ConnectivityResult.mobile ||
//                           _connectionStatus == ConnectivityResult.ethernet
//                       ? 'Online'
//                       : 'Offline',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: _connectionStatusColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Add a prominent connectivity status card at the top
//               Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: _connectionStatus == ConnectivityResult.none
//                       ? Colors.red.shade50
//                       : Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _connectionStatusColor.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       _connectionStatusIcon,
//                       color: _connectionStatusColor,
//                       size: 28,
//                     ),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Internet Status',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                         Text(
//                           _connectionStatusText,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: _connectionStatusColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 16.0),
//                 child: OutlinedButton(
//                   onPressed: _initConnectivity,
//                   child: const Text('Refresh Connection Status'),
//                 ),
//               ),

//               TextButton(
//                 onPressed: () async {
//                   await PortControl.shutDown();
//                 },
//                 child: const Text('Shutdown System'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   await PortControl.openHdmi(1);
//                   await Future.delayed(const Duration(seconds: 10));
//                   await PortControl.closeHdmi();
//                 },
//                 child: const Text('Open HDMI'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   await PortControl.closeHdmi();
//                 },
//                 child: const Text('Close HDMI'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final status = await PortControl.getHdmiStatus(1);
//                   setState(() {
//                     _hdmiStatus = status;
//                   });
//                 },
//                 child: const Text('Get HDMI Status'),
//               ),
//               (_hdmiStatus != null) ?  Text('HDMI Status: $_hdmiStatus') : SizedBox(),
//               TextButton(
//                 onPressed: () async {
//                   await PortControl.turnOff();
//                 },
//                 child: const Text('Turn Off'),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16.0),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Set BackLight',
//                       style: TextStyle(
//                         // fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8.0,
//                       runSpacing: 8.0,
//                       children:
//                           [25, 50, 75, 100].map((value) {
//                             return ElevatedButton(
//                               onPressed: () async {
//                                 await PortControl.setBackLight(value);
//                                 if (mounted) {
//                                   setState(() {
//                                     _currentBrightness = value;
//                                   });
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                     Theme.of(context).colorScheme.surface,
//                                 foregroundColor:
//                                     Theme.of(context).colorScheme.onSurface,
//                                 side: BorderSide(
//                                   color: Theme.of(context).colorScheme.outline,
//                                   width: 1,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 8,
//                                 ),
//                               ),
//                               child: Text(
//                                 '$value%',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             );
//                           }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final dir = await getExternalStorageDirectory();
//                   final filePath = "${dir!.path}/Pictures/screen_cap_1.jpg";
//                   final result = await PortControl.startScreenCap(filePath);
//                   print("Screen capture result: $result");
//                 },
//                 child: const Text('Start Screen Capture'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   const angles = [0, 90, 180, 270];
//                   setState(() {
//                     currentAngle =
//                         angles[(angles.indexOf(currentAngle) + 1) %
//                             angles.length];
//                   });
//                   await PortControl.setDisplayOrientation(currentAngle);
//                 },
//                 child: const Text('Rotate Screen'),
//               ),
//               Column(
//                 children: [
//                   TextButton(
//                     onPressed: () async {
//                       final volume = await PortControl.getSystemVoice();
//                       setState(() {
//                         _currentVolume = volume;
//                       });
//                     },
//                     child: const Text('Get Volume'),
//                   ),
//                   if (_currentVolume != null)
//                     Text('Current Volume: $_currentVolume'),
//                   Slider(
//                     value: (_currentVolume ?? 50).toDouble(),
//                     min: 0,
//                     max: 100,
//                     divisions: 10,
//                     onChanged: (value) async {
//                       await PortControl.setSystemVoice(value.toInt());
//                       setState(() {
//                         _currentVolume = value.toInt();
//                       });
//                     },
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       TextButton(
//                         onPressed: () async {
//                           await PortControl.mute();
//                           setState(() {
//                             _currentVolume = 0;
//                           });
//                         },
//                         child: const Text('Mute'),
//                       ),
//                       TextButton(
//                         onPressed: () async {
//                           await PortControl.unMute();
//                           final volume = await PortControl.getSystemVoice();
//                           setState(() {
//                             _currentVolume = volume;
//                           });
//                         },
//                         child: const Text('Unmute'),
//                       ),
//                     ],
//                   ),

//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 16.0),
//                     child: Column(
//                       children: [
//                         TextButton(
//                           onPressed: () async {
//                             await PortControl.reboot();
//                           },
//                           child: const Text('Reboot System'),
//                         ),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final mac = await PortControl.getMacAddress();
//                   setState(() => _macAddress = mac);
//                 },
//                 child: const Text('Get MAC Address'),
//               ),
//               if (_macAddress != null) Text('MAC: $_macAddress'),

//               TextButton(
//                 onPressed: () async {
//                   final id = await PortControl.getDeviceId();
//                   setState(() => _deviceId = id);
//                 },
//                 child: const Text('Get Device ID'),
//               ),
//               if (_deviceId != null) Text('Device ID: $_deviceId'),

//               TextButton(
//                 onPressed: () async {
//                   try {
//                     final sn = await PortControl.getSN();
//                     if (sn == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Failed to get serial number'),
//                         ),
//                       );
//                     }
//                     setState(() => _serialNumber = sn ?? 'Not available');
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error: ${e.toString()}')),
//                     );
//                   }
//                 },
//                 child: const Text('Get Serial Number'),
//               ),
//               if (_serialNumber != null)
//                 Text(
//                   'SN: $_serialNumber',
//                   style: TextStyle(
//                     color:
//                         _serialNumber == 'Not available'
//                             ? Colors.red
//                             : Colors.black,
//                   ),
//                 ),

//               TextButton(
//                 onPressed: () async {
//                   final type = await PortControl.getClientType();
//                   setState(() => _clientType = type);
//                 },
//                 child: const Text('Get Client Type'),
//               ),
//               if (_clientType != null) Text('Client Type: $_clientType'),

//               TextButton(
//                 onPressed: () async {
//                   final appId = await PortControl.getAppId();
//                   setState(() => _appId = appId);
//                 },
//                 child: const Text('Get App ID'),
//               ),
//               if (_appId != null) Text('App ID: $_appId'),

//               TextButton(
//                 onPressed: () async {
//                   // final value = await LaunchApp.isAppInstalled(
//                   //   androidPackageName: "com.example.wauly_app",
//                   // );
//                   await LaunchApp.openApp(
//                     androidPackageName: "com.example.wauly_app",
//                   );
//                   // print(value);
//                 },
//                 child: const Text('Open Another App'),
//               ),
//             ],
//           ),
//         ),

//       ),
//     );
//   }
// }

import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:panasonic_port/wauly_monitor_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:panasonic_port/Port_Control.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
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

  String? _macAddress;
  String? _deviceId;
  String? _serialNumber;
  String? _clientType;
  String? _appId;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentBrightness();
    _initConnectivity();
    _listenForConnectivityChanges();
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
                      _buildCompactButton(
                        'Capture',
                        Icons.camera,
                        () async {
                          final dir = await getExternalStorageDirectory();
                          final filePath =
                              "${dir!.path}/Pictures/screen_cap_1.jpg";
                          await PortControl.startScreenCap(filePath);
                        },
                      ),
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

                  // App Launcher Section
                  _buildSectionTitle('Applications'),
                  _buildCompactButton(
                    'Open Another App',
                    Icons.open_in_new,
                    () => LaunchApp.openApp(
                      androidPackageName: "com.example.wauly_app",
                    ),
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
