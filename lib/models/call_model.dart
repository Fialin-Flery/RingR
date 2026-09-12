enum CallType {
  incoming,
  outgoing,
  missed,
}

enum CallStatus {
  calling,
  ringing,
  connected,
  ended,
  rejected,
  missed,
  busy,
  failed,
  disconnected,
  cancelled,
}

enum CallMode {
  audio,
  video,
}

class CallModel {
  final String callId;

  final String name;

  final String? phoneNumber;

  final String? uid;

  final CallType type;

  final CallStatus status;

  final CallMode mode;

  /// Time at which the call record was created.
  final DateTime time;

  /// Time at which the call actually became connected.
  final DateTime? connectedAt;

  /// Time at which the call ended.
  final DateTime? endedAt;

  /// Actual connected duration.
  final Duration duration;

  const CallModel({
    required this.callId,
    required this.name,
    this.phoneNumber,
    this.uid,
    required this.type,
    required this.status,
    required this.mode,
    required this.time,
    this.connectedAt,
    this.endedAt,
    this.duration = Duration.zero,
  });

  bool get isMissed =>
      status == CallStatus.missed ||
          type == CallType.missed;

  bool get isRejected =>
      status == CallStatus.rejected;

  bool get isBusy =>
      status == CallStatus.busy;

  bool get isFailed =>
      status == CallStatus.failed;

  bool get isCompleted =>
      status == CallStatus.ended;

  bool get isConnected =>
      status == CallStatus.connected;

  bool get hasDuration =>
      duration > Duration.zero;

  CallModel copyWith({
    String? callId,
    String? name,
    String? phoneNumber,
    String? uid,
    CallType? type,
    CallStatus? status,
    CallMode? mode,
    DateTime? time,
    DateTime? connectedAt,
    DateTime? endedAt,
    Duration? duration,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      time: time ?? this.time,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'callId': callId,
      'name': name,
      'phoneNumber': phoneNumber,
      'uid': uid,
      'type': type.name,
      'status': status.name,
      'mode': mode.name,
      'time': time.millisecondsSinceEpoch,
      'connectedAt':
      connectedAt?.millisecondsSinceEpoch,
      'endedAt':
      endedAt?.millisecondsSinceEpoch,
      'durationSeconds': duration.inSeconds,
    };
  }

  factory CallModel.fromMap(
      Map<String, Object?> map) {
    return CallModel(
      callId: map['callId'] as String,
      name: map['name'] as String? ?? 'Ringr User',
      phoneNumber:
      map['phoneNumber'] as String?,
      uid: map['uid'] as String?,
      type: CallType.values.firstWhere(
            (value) =>
        value.name == map['type'],
        orElse: () => CallType.outgoing,
      ),
      status: CallStatus.values.firstWhere(
            (value) =>
        value.name == map['status'],
        orElse: () => CallStatus.failed,
      ),
      mode: CallMode.values.firstWhere(
            (value) =>
        value.name == map['mode'],
        orElse: () => CallMode.audio,
      ),
      time: DateTime.fromMillisecondsSinceEpoch(
        map['time'] as int,
      ),
      connectedAt:
      map['connectedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
        map['connectedAt'] as int,
      ),
      endedAt:
      map['endedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
        map['endedAt'] as int,
      ),
      duration: Duration(
        seconds:
        map['durationSeconds'] as int? ?? 0,
      ),
    );
  }
}