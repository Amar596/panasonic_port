import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class WaulyMonitorScreen extends StatefulWidget {
  @override
  _WaulyMonitorScreenState createState() => _WaulyMonitorScreenState();
}

class _WaulyMonitorScreenState extends State<WaulyMonitorScreen> with WidgetsBindingObserver {
  static const MethodChannel _methodChannel = MethodChannel('port_control');
  static const EventChannel _eventChannel =
      EventChannel('com.example.panasonic_port/monitoring_events');

  String _lastMessage = 'No messages received yet';
  String _lastMessageTime = 'N/A';
  String _lastActiveTime = 'N/A';
  String _appStatus = 'UNKNOWN';
  List<Map<String, dynamic>> _messageHistory = [];
  StreamSubscription<dynamic>? _eventSubscription;
  bool _isListening = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaulyStatus();
    _loadSavedHistory();
    _startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    _saveHistory();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App going to background - save immediately
      _saveHistory();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - reload
      _loadSavedHistory();
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Load history first
    await _loadSavedHistory();

    // Then load status
    await _loadWaulyStatus();

    // Start listening
    _startListening();

    setState(() => _isLoading = false);
  }

  // Load saved history from SharedPreferences
  Future<void> _loadSavedHistory() async {
    try {
      print('📂 Loading saved history...');
      final historyJson =
          await _methodChannel.invokeMethod<String>('loadMessageHistory');
      print('📂 History JSON: $historyJson');

      if (historyJson != null &&
          historyJson.isNotEmpty &&
          historyJson != '[]') {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messageHistory = decoded.map<Map<String, dynamic>>((item) {
            return {
              'message': item['message']?.toString() ?? '',
              'timestamp': item['timestamp']?.toString() ?? '',
              'type': item['type']?.toString() ?? 'info',
            };
          }).toList();
          print('📂 Loaded ${_messageHistory.length} messages from storage');

          // Update last message from history if available
          if (_messageHistory.isNotEmpty) {
            _lastMessage = _messageHistory.first['message'] ?? _lastMessage;
            _lastMessageTime =
                _messageHistory.first['timestamp'] ?? _lastMessageTime;
          }
        });
      } else {
        print('📂 No saved history found');
      }
    } on PlatformException catch (e) {
      print('❌ Failed to load history: ${e.message}');
    } catch (e) {
      print('❌ Failed to parse history: $e');
    }
  }

  // Save history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      if (_messageHistory.isEmpty) {
        print('💾 No messages to save');
        return;
      }

      // Ensure all values are strings before encoding
      final List<Map<String, String>> historyForStorage =
          _messageHistory.map((item) {
        return {
          'message': item['message']?.toString() ?? '',
          'timestamp': item['timestamp']?.toString() ?? '',
          'type': item['type']?.toString() ?? 'info',
        };
      }).toList();

      final historyJson = jsonEncode(historyForStorage);
      await _methodChannel
          .invokeMethod('saveMessageHistory', {'history': historyJson});
      print('💾 Saved ${_messageHistory.length} messages to storage');
    } on PlatformException catch (e) {
      print('❌ Failed to save history: ${e.message}');
    }
  }

  void _startListening() {
    try {
      _isListening = true;
      _eventSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
      print('🎧 Started listening for Wauly messages...');
    } catch (e) {
      print('❌ Error starting listener: $e');
      _isListening = false;
    }
  }

  void _onEvent(dynamic event) {
    print('=== RECEIVED EVENT ===');
    print('Raw event: $event');

    if (event is Map) {
      final message = event['message'] ?? '';
      final timestamp = event['timestamp'] ?? '';
      final type = event['type'] ?? 'info';

      print('Adding to history - Type: $type, Message: $message');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _lastMessage = message;
          _lastMessageTime = timestamp;

          // Update last active time for ALL messages except stopped
          if (type != 'stopped') {
            _lastActiveTime = timestamp;
          }

          // Update app status
          if (type == 'started' ||
              type == 'alive' ||
              type == 'heartbeat' ||
              type == 'running') {
            _appStatus = 'RUNNING';
          } else if (type == 'stopped') {
            _appStatus = 'STOPPED';
          } else if (type == 'background') {
            _appStatus = 'BACKGROUND';
          } else if (type == 'test') {
            _appStatus = 'TESTING';
          }

          // Check for duplicate before adding
          bool isDuplicate = false;
          if (_messageHistory.isNotEmpty) {
            final lastMessage = _messageHistory.first;
            if (lastMessage['message'] == message &&
                lastMessage['type'] == type &&
                DateTime.now().difference(DateTime.parse(timestamp)).inSeconds <
                    1) {
              isDuplicate = true;
              print('⚠️ Duplicate message ignored');
            }
          }

          if (!isDuplicate) {
            // Add to history
            _messageHistory.insert(0, {
              'message': message.toString(),
              'timestamp': timestamp.toString(),
              'type': type.toString(),
            });

            // Keep only last 50 messages
            if (_messageHistory.length > 50) {
              _messageHistory.removeLast();
            }

            // Save immediately when new message arrives
            _saveHistory();

            print('History now has ${_messageHistory.length} messages');
          }
        });
      });
    } else {
      print('Event is not a Map, it is: ${event.runtimeType}');
    }
  }

  void _onError(Object error) {
    print('Error receiving events: $error');
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _loadWaulyStatus() async {
    try {
      print('Loading Wauly status...');
      final status = await _methodChannel.invokeMethod<Map>('getWaulyStatus');
      print('Received status: $status');
      if (status != null) {
        setState(() {
          _lastMessage = status['lastMessage'] ?? _lastMessage;
          _lastMessageTime = status['lastMessageTime'] ?? _lastMessageTime;
          _lastActiveTime = status['lastActiveTime'] ?? _lastActiveTime;
          _appStatus = status['appStatus'] ?? _appStatus;
        });
      }
    } on PlatformException catch (e) {
      print('Failed to get wauly status: ${e.message}');
    }
  }

  Future<void> _clearData() async {
    try {
      await _methodChannel.invokeMethod('clearWaulyData');
      setState(() {
        _lastMessage = 'No messages received yet';
        _lastMessageTime = 'N/A';
        _lastActiveTime = 'N/A';
        _appStatus = 'UNKNOWN';
        _messageHistory.clear();
      });
      print('Data cleared');
    } on PlatformException catch (e) {
      print('Failed to clear data: ${e.message}');
    }
  }

  Future<void> _testConnection() async {
    try {
      // Send a test message to check if Flutter is receiving events
      print('Testing connection...');
      print('Is listening: $_isListening');
      print('Event subscription: ${_eventSubscription != null}');
    } on PlatformException catch (e) {
      print('Test failed: ${e.message}');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RUNNING':
        return Colors.green;
      case 'STOPPED':
        return Colors.red;
      case 'BACKGROUND':
        return Colors.orange;
      case 'TESTING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'RUNNING':
        return Icons.play_circle_filled;
      case 'STOPPED':
        return Icons.stop_circle;
      case 'BACKGROUND':
        return Icons.pause_circle_filled;
      case 'TESTING':
        return Icons.bug_report;
      default:
        return Icons.help;
    }
  }

  Color _getMessageColor(String type) {
    final typeStr = type?.toString() ?? '';
    switch (type) {
      case 'started':
        return Colors.green;
      case 'stopped':
        return Colors.red;
      case 'background':
        return Colors.orange;
      case 'alive':
      case 'heartbeat':
      case 'running':
        return Colors.blue;
      case 'test':
        return Colors.purple;
      case 'crash':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMessageTypeDisplay(String type) {
    switch (type) {
      case 'started':
        return 'STARTED';
      case 'stopped':
        return 'STOPPED';
      case 'background':
        return 'BACKGROUND';
      case 'alive':
        return 'ALIVE';
      case 'heartbeat':
        return 'HEARTBEAT';
      case 'running':
        return 'RUNNING';
      case 'test':
        return 'TEST';
      case 'crash':
        return 'CRASH';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wauly App Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWaulyStatus,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Last Active Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Active Time',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _lastActiveTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Message History
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _messageHistory.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                // reverse: true,
                                itemCount: _messageHistory.length,
                                itemBuilder: (context, index) {
                                  final message = _messageHistory[index];
                                  return ListTile(
                                    leading: Icon(
                                      _getMessageIcon(message['type']),
                                      color: _getMessageColor(message['type']),
                                      size: 18,
                                    ),
                                    title: Text(
                                      message['message'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                      ),
                                    ),
                                    subtitle: Text(message['timestamp'],
                                    style: const TextStyle(
                                        fontSize: 10,
                                      ),
                                    ),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    onTap: () {
                                      _showMessageDetails(message);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMessageIcon(dynamic type) {
    final typeStr = type?.toString() ?? '';
    switch (typeStr) {
      case 'started':
        return Icons.play_arrow;
      case 'stopped':
        return Icons.stop;
      case 'background':
        return Icons.pause;
      case 'alive':
        return Icons.favorite;
      case 'heartbeat':
        return Icons.favorite_border;
      case 'running':
        return Icons.directions_run;
      case 'test':
        return Icons.bug_report;
      case 'crash':
        return Icons.error;
      default:
        return Icons.message;
    }
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type: ${message['type']?.toUpperCase() ?? 'UNKNOWN'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Time: ${message['timestamp']}'),
              const SizedBox(height: 16),
              const Text('Message:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  message['message'],
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
