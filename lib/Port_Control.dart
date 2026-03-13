import 'package:flutter/services.dart';

class PortControl {
  static const MethodChannel _channel = MethodChannel('port_control');
  static const int _brightnessStep = 25;

  static Future<void> openHdmi(int index) async {
    await _channel.invokeMethod('openHDMI', {'index': index});
  }

  static Future<void> closeHdmi() async {
    await _channel.invokeMethod('closeHDMI');
  }

  static Future<int?> getHdmiStatus(int index) async {
    final result = await _channel.invokeMethod<int>('getHDMIStatus', {
      'index': index,
    });
    return result;
  }

  static Future<bool?> getHdmiMode() async {
    return await _channel.invokeMethod<bool>('getHDMIMode');
  }

  static Future<bool> setHdmiMode(bool status) async {
    try {
      final result = await _channel.invokeMethod<bool>('setHdmiMode', {
        'status': status,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to set HDMI mode: ${e.message}');
      return false;
    }
  }

  static Future<void> shutDown() async {
    await _channel.invokeMethod('shutdownSystem');
  }

  static Future<void> setDelayPowerOn(int mins) async =>
      _channel.invokeMethod('setDelayPowerOn', {'mins': mins});

  static Future<void> turnOff() async => _channel.invokeMethod('turnOff');

  static Future<bool?> isInteractive() async =>
      _channel.invokeMethod<bool>('isInteractive');

  static Future<void> setPowerControlSleep() async =>
      _channel.invokeMethod('setPowerControlSleep');

  static Future<void> setBackLight(int value) async {
    await _channel.invokeMethod('setBackLight', {'value': value});
  }

  static Future<int?> startScreenCap(String fileName) async {
    final result = await _channel.invokeMethod<int>('startScreenCap', {
      'fileName': fileName,
    });
    return result;
  }

  static Future<void> setDisplayOrientation(int angle) async {
    await _channel.invokeMethod('setDisplayOrientation', {'angle': angle});
  }

  static Future<int?> getSystemVoice() async {
    return await _channel.invokeMethod<int>('getSystemVoice');
  }

  static Future<void> setSystemVoice(int voice) async {
    await _channel.invokeMethod('setSystemVoice', {'voice': voice});
  }

  static Future<void> mute() async {
    await _channel.invokeMethod('mute');
  }

  static Future<void> unMute() async {
    await _channel.invokeMethod('unMute');
  }

  static Future<void> reboot() async {
    try {
      await _channel.invokeMethod('reboot');
    } on PlatformException catch (e) {
      print('Failed to reboot: ${e.message}');
      rethrow;
    }
  }

  static Future<bool> setSystemAutoReboot({
    required int status,
    required String time,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('setSystemAutoReboot', {
        'status': status,
        'time': time,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to set auto reboot: ${e.message}');
      return false;
    }
  }

  static Future<String?> getMacAddress() async {
    try {
      return await _channel.invokeMethod<String>('getMacAddress');
    } on PlatformException catch (e) {
      print('Failed to get MAC address: ${e.message}');
      return null;
    }
  }

  static Future<String?> getDeviceId() async {
    try {
      return await _channel.invokeMethod<String>('getDeviceId');
    } on PlatformException catch (e) {
      print('Failed to get device ID: ${e.message}');
      return null;
    }
  }


  static Future<String?> getSN() async {
    try {
      final sn = await _channel.invokeMethod<String>('getSN');
      if (sn == null || sn.isEmpty) {
        print('Received empty serial number');
        return null;
      }
      return sn;
    } on PlatformException catch (e) {
      print('Failed to get serial number: ${e.message}');
      print('Details: ${e.details}');
      return null;
    } catch (e) {
      print('Unexpected error getting SN: $e');
      return null;
    }
  }

  static Future<String?> getClientType() async {
    try {
      return await _channel.invokeMethod<String>('getClientType');
    } on PlatformException catch (e) {
      print('Failed to get client type: ${e.message}');
      return null;
    }
  }

  static Future<String?> getAppId() async {
    try {
      return await _channel.invokeMethod<String>('getAppId');
    } on PlatformException catch (e) {
      print('Failed to get app ID: ${e.message}');
      return null;
    }
  }

  static Future<void> increaseBrightness() async {
    final current = await getCurrentBrightness() ?? 0;
    final newBrightness = (current + _brightnessStep).clamp(0, 100);
    await setBackLight(newBrightness);
  }

  static Future<void> decreaseBrightness() async {
    final current = await getCurrentBrightness() ?? 0;
    final newBrightness = (current - _brightnessStep).clamp(0, 100);
    await setBackLight(newBrightness);
  }

  static Future<int?> getCurrentBrightness() async {
    // You might need to implement this method in your platform-specific code
    // if you need to get the current brightness value
    // For now, we'll just return null and handle it in the UI
    return null;
  }
}
