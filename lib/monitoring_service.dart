import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'monitoring_model.dart';

class MonitoringService {
  static const String _channel = 'com.example.panasonic_port/monitoring';
  static const MethodChannel _methodChannel = MethodChannel(_channel);

  static const int _maxSavedEvents = 100;

  List<MonitoringEvent> _events = [];
  WaulyStatus? _currentStatus;
  late File _eventsFile;
  late File _statusFile;

  final StreamController<List<MonitoringEvent>> _eventsController =
      StreamController<List<MonitoringEvent>>.broadcast();
  final StreamController<WaulyStatus> _statusController =
      StreamController<WaulyStatus>.broadcast();

  Stream<List<MonitoringEvent>> get eventsStream => _eventsController.stream;
  Stream<WaulyStatus> get statusStream => _statusController.stream;

  List<MonitoringEvent> get events => List.unmodifiable(_events);
  WaulyStatus? get currentStatus => _currentStatus;

  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  Future<void> initialize() async {
    print('[MonitoringService] 🔧 Initializing...');

    try {
      // Initialize files
      final directory = await getApplicationDocumentsDirectory();
      _eventsFile = File('${directory.path}/monitoring_events.json');
      _statusFile = File('${directory.path}/wauly_status.json');

      print('[MonitoringService] 📁 Files initialized');

      // Load saved data
      await _loadEvents();
      await _loadStatus();

      print(
          '[MonitoringService] 📊 Loaded ${_events.length} events from storage');

      // Test connection
      await Future.delayed(const Duration(milliseconds: 500));
      await testConnection();
    } catch (e) {
      print('[MonitoringService] 💥 Initialization error: $e');

      addEvent(MonitoringEvent(
        timestamp: DateTime.now().toIso8601String(),
        message: 'Monitoring service error: $e',
        type: 'error',
      ));
    }
  }

  Future<void> testConnection() async {
    try {
      print('[MonitoringService] 🔌 Testing connection...');
      final result = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('testConnection');
      print('[MonitoringService] ✅ Connection test successful: $result');

      if (result != null) {
        addEvent(MonitoringEvent(
          timestamp: result['timestamp']?.toString() ??
              DateTime.now().toIso8601String(),
          message: result['message']?.toString() ??
              'Connected to monitoring service',
          type: 'info',
        ));
      }
    } on PlatformException catch (e) {
      print('[MonitoringService] ❌ Connection test failed: ${e.message}');
      addEvent(MonitoringEvent(
        timestamp: DateTime.now().toIso8601String(),
        message: 'Connection failed: ${e.message}',
        type: 'error',
      ));
    }
  }

  Future<void> sendSelfTest() async {
    try {
      print('[MonitoringService] 🧪 Sending self-test...');

      // Get list of test events from native
      final response =
          await _methodChannel.invokeMethod<List<dynamic>>('sendSelfTest');

      if (response != null && response.isNotEmpty) {
        print('[MonitoringService] 📋 Received ${response.length} test events');

        // Process each event
        for (var eventData in response) {
          if (eventData is Map) {
            try {
              final eventMap = Map<String, dynamic>.from(eventData);
              final event = MonitoringEvent.fromJson(eventMap);
              addEvent(event);

              // Update status for alive events
              if (event.type == 'alive') {
                _currentStatus = WaulyStatus(
                  lastAliveMessage: event.message,
                  lastAliveTime: DateTime.parse(event.timestamp),
                  isRunning: true,
                );
                _statusController.add(_currentStatus!);
                _saveStatus();
              }
            } catch (e) {
              print('[MonitoringService] ⚠️ Error parsing event: $e');
            }
          }
        }
      } else {
        print('[MonitoringService] ⚠️ No events returned from self-test');
        addEvent(MonitoringEvent(
          timestamp: DateTime.now().toIso8601String(),
          message: 'Self-test returned no events',
          type: 'warning',
        ));
      }
    } on PlatformException catch (e) {
      print('[MonitoringService] ❌ Self-test failed: ${e.code} - ${e.message}');
      addEvent(MonitoringEvent(
        timestamp: DateTime.now().toIso8601String(),
        message: 'Self-test failed: ${e.message}',
        type: 'error',
      ));
    }
  }

  Future<void> getEventsFromNative() async {
    try {
      print('[MonitoringService] 📨 Getting events from native...');
      final events =
          await _methodChannel.invokeMethod<List<dynamic>>('getEvents');

      if (events != null) {
        for (var eventData in events) {
          if (eventData is Map) {
            final event =
                MonitoringEvent.fromJson(Map<String, dynamic>.from(eventData));
            addEvent(event);
          }
        }
      }
    } on PlatformException catch (e) {
      print('[MonitoringService] Error getting events: ${e.message}');
    }
  }

  Future<Map<dynamic, dynamic>?> getSystemInfo() async {
    try {
      return await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getSystemInfo');
    } on PlatformException catch (e) {
      print('[MonitoringService] Error getting system info: ${e.message}');
      rethrow;
    }
  }

  Future<Map<dynamic, dynamic>?> getDeviceStatus() async {
    try {
      return await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getDeviceStatus');
    } on PlatformException catch (e) {
      print('[MonitoringService] Error getting device status: ${e.message}');
      rethrow;
    }
  }

  Future<String?> ping() async {
    try {
      return await _methodChannel.invokeMethod<String>('ping');
    } on PlatformException catch (e) {
      print('[MonitoringService] Ping failed: ${e.message}');
      rethrow;
    }
  }

  // File operations (keep these as they are)
  Future<void> _loadEvents() async {
    try {
      if (await _eventsFile.exists()) {
        final content = await _eventsFile.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _events =
            jsonList.map((json) => MonitoringEvent.fromJson(json)).toList();
        _eventsController.add(_events);
      }
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<void> _loadStatus() async {
    try {
      if (await _statusFile.exists()) {
        final content = await _statusFile.readAsString();
        final jsonData = json.decode(content);
        _currentStatus = WaulyStatus.fromJson(jsonData);
        if (_currentStatus != null) {
          _statusController.add(_currentStatus!);
        }
      }
    } catch (e) {
      print('Error loading status: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final jsonList = _events.map((event) => event.toJson()).toList();
      await _eventsFile.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving events: $e');
    }
  }

  Future<void> _saveStatus() async {
    try {
      if (_currentStatus != null) {
        await _statusFile.writeAsString(json.encode(_currentStatus!.toJson()));
      }
    } catch (e) {
      print('Error saving status: $e');
    }
  }

  void addEvent(MonitoringEvent event) {
    _events.insert(0, event); // Add to beginning

    if (_events.length > _maxSavedEvents) {
      _events.removeRange(_maxSavedEvents, _events.length);
    }

    _eventsController.add(_events);
    _saveEvents();
  }

  Future<void> clearEvents() async {
    _events.clear();
    _eventsController.add(_events);
    await _saveEvents();
  }

  Future<Map<dynamic, dynamic>?> getWaulyAppStatus() async {
    try {
      return await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getWaulyAppStatus');
    } on PlatformException catch (e) {
      print('[MonitoringService] Error getting WAULY status: ${e.message}');
      return null;
    }
  }

  void dispose() {
    _eventsController.close();
    _statusController.close();
  }

  connectToWauly() {}
}
