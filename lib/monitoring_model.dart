class MonitoringEvent {
  final String timestamp;
  final String message;
  final String type; // 'alive', 'status', 'error', 'info'

  MonitoringEvent({
    required this.timestamp,
    required this.message,
    required this.type,
  });

  factory MonitoringEvent.fromJson(Map<String, dynamic> json) {
    return MonitoringEvent(
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '', type: '',
      //type: json['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'message': message,
      //'type': type,
    };
  }

  @override
  String toString() {
    return '[$timestamp] $message';
  }
}

class WaulyStatus {
  final String lastAliveMessage;
  final DateTime lastAliveTime;
  final bool isRunning;


  WaulyStatus({
    required this.lastAliveMessage,
    required this.lastAliveTime,
    required this.isRunning,
  });

  factory WaulyStatus.fromJson(Map<String, dynamic> json) {
    return WaulyStatus(
      lastAliveMessage: json['lastAliveMessage'] ?? '',
      lastAliveTime: DateTime.parse(
          json['lastAliveTime'] ?? DateTime.now().toIso8601String()),
      isRunning: json['isRunning'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastAliveMessage': lastAliveMessage,
      'lastAliveTime': lastAliveTime.toIso8601String(),
      'isRunning': isRunning,
    };
  }
}


