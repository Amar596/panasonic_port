import 'dart:math';
import 'package:flutter/services.dart';

class StorageInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
  });

  String get formattedTotalSpace => _formatBytes(totalSpace);
  String get formattedFreeSpace => _formatBytes(freeSpace);
  String get formattedUsedSpace => _formatBytes(usedSpace);

  double get usedPercentage =>
      totalSpace > 0 ? (usedSpace / totalSpace) * 100 : 0;
  double get freePercentage =>
      totalSpace > 0 ? (freeSpace / totalSpace) * 100 : 0;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes.toDouble()) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}

class StorageService {
  // ✅ Must match CHANNEL = "port_control" in MainActivity.kt
  static const platform = MethodChannel('port_control');

  Future<StorageInfo> getStorageInfo() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getStorageInfo');

      final totalSpace = result['totalSpace'] as int;
      final freeSpace = result['freeSpace'] as int;

      return StorageInfo(
        totalSpace: totalSpace,
        freeSpace: freeSpace,
        usedSpace: totalSpace - freeSpace,
      );
    } catch (e) {
      print('Error getting storage info: $e');
      return StorageInfo(totalSpace: 0, freeSpace: 0, usedSpace: 0);
    }
  }
}
