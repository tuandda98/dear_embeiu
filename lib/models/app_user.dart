class AppUser {
  static const Object _unset = Object();

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? coupleId;
  final String inviteCode;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.coupleId,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
  });

  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;
  bool get hasInviteCode => inviteCode.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'status': status,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastSeenAt': lastSeenAt,
      };

  // Payload for merge-updates of an existing doc. Intentionally omits the
  // immutable `createdAt`: re-sending it round-trips the value through
  // DateTime, and on iOS the DateTime→Timestamp conversion drifts by a few
  // nanoseconds, which breaks the exact-equality `createdAt` check in
  // firestore.rules and yields permission-denied. Merge keeps the stored value.
  Map<String, dynamic> toFirestoreUpdate() => {
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'status': status,
        'updatedAt': updatedAt,
        'lastSeenAt': lastSeenAt,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        coupleId: json['coupleId'] as String?,
        inviteCode: json['inviteCode'] as String? ?? '',
        status: json['status'] as String? ?? 'single',
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
        lastSeenAt: _parseDateTime(json['lastSeenAt']),
      );

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    Object? avatarUrl = _unset,
    Object? coupleId = _unset,
    String? inviteCode,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastSeenAt = _unset,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: identical(avatarUrl, _unset) ? this.avatarUrl : avatarUrl as String?,
      coupleId: identical(coupleId, _unset) ? this.coupleId : coupleId as String?,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: identical(lastSeenAt, _unset) ? this.lastSeenAt : lastSeenAt as DateTime?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    // Firestore Timestamp: read with microsecond precision so a read→write
    // round-trip is lossless. Truncating to milliseconds would change the
    // value and trip the immutable-`createdAt` checks in firestore.rules.
    final dynamic microsecondsSinceEpoch = (value as dynamic).microsecondsSinceEpoch;
    if (microsecondsSinceEpoch is int) {
      return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
    }

    final dynamic millisecondsSinceEpoch = (value as dynamic).millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }

    return null;
  }
}

