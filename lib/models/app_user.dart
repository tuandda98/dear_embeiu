class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? coupleId;
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
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
  });

  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'coupleId': coupleId,
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
        'status': status,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastSeenAt': lastSeenAt,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        coupleId: json['coupleId'] as String?,
        status: json['status'] as String? ?? 'single',
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
        lastSeenAt: _parseDateTime(json['lastSeenAt']),
      );

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? coupleId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coupleId: coupleId ?? this.coupleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
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

    final dynamic millisecondsSinceEpoch = (value as dynamic).millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }

    return null;
  }
}

