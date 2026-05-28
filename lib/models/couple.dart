class Couple {
  final String id;
  final String person1Name;
  final String person2Name;
  final DateTime anniversaryDate;
  final String? couplePhotoPath;
  final String? couplePhotoUrl;
  final String? couplePhotoStoragePath;
  final String inviteCode;
  final List<String> memberIds;
  final int memberCount;
  final String createdByUserId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Couple({
    required this.id,
    required this.person1Name,
    required this.person2Name,
    required this.anniversaryDate,
    this.couplePhotoPath,
    this.couplePhotoUrl,
    this.couplePhotoStoragePath,
    required this.inviteCode,
    required this.memberIds,
    required this.memberCount,
    required this.createdByUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isWaitingForPartner => memberCount < 2 || status == 'waiting_partner';

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'person1Name': person1Name,
    'person2Name': person2Name,
    'anniversaryDate': anniversaryDate.toIso8601String(),
    'couplePhotoPath': couplePhotoPath,
    'couplePhotoUrl': couplePhotoUrl,
    'couplePhotoStoragePath': couplePhotoStoragePath,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
    'memberCount': memberCount,
    'createdByUserId': createdByUserId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'person1Name': person1Name,
    'person2Name': person2Name,
    'anniversaryDate': anniversaryDate,
    'couplePhotoPath': '',
    'couplePhotoUrl': couplePhotoUrl,
    'couplePhotoStoragePath': couplePhotoStoragePath,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
    'memberCount': memberCount,
    'createdByUserId': createdByUserId,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  // Create from JSON
  factory Couple.fromJson(Map<String, dynamic> json) => Couple(
    id: json['id'] as String? ?? '',
    person1Name: json['person1Name'] as String? ?? '',
    person2Name: json['person2Name'] as String? ?? '',
    anniversaryDate: _parseDateTime(json['anniversaryDate']) ?? DateTime.now(),
    couplePhotoPath: json['couplePhotoPath'] as String?,
    couplePhotoUrl: json['couplePhotoUrl'] as String?,
    couplePhotoStoragePath: json['couplePhotoStoragePath'] as String?,
    inviteCode: json['inviteCode'] as String? ?? '',
    memberIds: (json['memberIds'] as List?)?.map((e) => '$e').toList() ?? const [],
    memberCount: json['memberCount'] as int? ?? ((json['memberIds'] as List?)?.length ?? 0),
    createdByUserId: json['createdByUserId'] as String? ?? '',
    status: json['status'] as String? ?? 'waiting_partner',
    createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
  );

  // Copy with method
  Couple copyWith({
    String? id,
    String? person1Name,
    String? person2Name,
    DateTime? anniversaryDate,
    String? couplePhotoPath,
    String? couplePhotoUrl,
    String? couplePhotoStoragePath,
    String? inviteCode,
    List<String>? memberIds,
    int? memberCount,
    String? createdByUserId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Couple(
        id: id ?? this.id,
        person1Name: person1Name ?? this.person1Name,
        person2Name: person2Name ?? this.person2Name,
        anniversaryDate: anniversaryDate ?? this.anniversaryDate,
        couplePhotoPath: couplePhotoPath ?? this.couplePhotoPath,
        couplePhotoUrl: couplePhotoUrl ?? this.couplePhotoUrl,
        couplePhotoStoragePath:
            couplePhotoStoragePath ?? this.couplePhotoStoragePath,
        inviteCode: inviteCode ?? this.inviteCode,
        memberIds: memberIds ?? this.memberIds,
        memberCount: memberCount ?? this.memberCount,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

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

