class Couple {
  final String id;
  final String person1Name;
  final String person2Name;
  final DateTime anniversaryDate;
  final String? couplePhotoPath;
  final String? couplePhotoUrl;
  final String? couplePhotoStoragePath;
  final String inviteCode;
  // Separate couple-level entry code — independent from the personal inviteCode.
  // Generated fresh when the couple is created. Used by setup screen and join
  // flow instead of the personal inviteCode so leaving and rejoining works
  // without resetting the personal code. Null on legacy couples (pre-feature).
  final String? coupleCode;
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
    this.coupleCode,
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
    'coupleCode': coupleCode,
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
    'coupleCode': coupleCode,
    'memberIds': memberIds,
    'memberCount': memberCount,
    'createdByUserId': createdByUserId,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  // Payload for a profile edit (name/anniversary/photo) of an EXISTING couple.
  // Deliberately sends ONLY the seven user-editable fields and NOT the
  // structural/immutable ones (memberIds, memberCount, status, inviteCode,
  // createdByUserId, createdAt). Written with SetOptions(merge: true) so the
  // server's stored structural fields are preserved untouched.
  //
  // This is the fix for `coupleSavePermissionDenied`: the rule
  // `isCoupleProfileEdit` requires
  //   request.resource.data.memberIds  == resource.data.memberIds
  //   request.resource.data.memberCount == resource.data.memberCount
  //   request.resource.data.status      == resource.data.status
  //   + coupleMetadataIsImmutable() (inviteCode/createdByUserId/createdAt)
  // If we re-send these from a possibly-stale LOCAL couple (e.g. local status
  // still 'waiting_partner' while the server is 'active', or local memberIds
  // out of sync), the equality checks fail → permission-denied. By omitting
  // them entirely, merge leaves the server values in place so both sides of
  // every equality are the server value → the rule always passes regardless
  // of how stale the local copy is.
  Map<String, dynamic> toProfileEditPayload() => {
    'person1Name': person1Name,
    'person2Name': person2Name,
    'anniversaryDate': anniversaryDate,
    'couplePhotoPath': '',
    'couplePhotoUrl': couplePhotoUrl,
    'couplePhotoStoragePath': couplePhotoStoragePath,
    'updatedAt': updatedAt,
  };

  // Narrow payload for writing ONLY the hero-photo fields of an existing
  // couple (used right after creation when the cover upload finishes). Same
  // rationale as [toProfileEditPayload]: never re-send structural/immutable
  // fields, so the `isCoupleProfileEdit` equality checks pass via merge.
  Map<String, dynamic> toPhotoEditPayload() => {
    'couplePhotoPath': '',
    'couplePhotoUrl': couplePhotoUrl,
    'couplePhotoStoragePath': couplePhotoStoragePath,
    'updatedAt': updatedAt,
  };

  // Payload for merge-updates of an existing couple. Omits the immutable
  // `createdAt`: re-sending it round-trips through DateTime and on iOS the
  // DateTime→Timestamp conversion drifts by a few nanoseconds, breaking the
  // exact-equality `createdAt` check in firestore.rules (permission-denied).
  // Merge keeps the stored value.
  //
  // Still used for the JOIN / LEAVE couple transitions, which MUST change
  // memberIds/memberCount/status (rules `isCoupleJoinTransition` /
  // `isCoupleLeaveTransition` require the new values). Do NOT use this for a
  // plain profile edit — use [toProfileEditPayload] instead.
  Map<String, dynamic> toFirestoreUpdate() => {
    'person1Name': person1Name,
    'person2Name': person2Name,
    'anniversaryDate': anniversaryDate,
    'couplePhotoPath': '',
    'couplePhotoUrl': couplePhotoUrl,
    'couplePhotoStoragePath': couplePhotoStoragePath,
    'inviteCode': inviteCode,
    'coupleCode': coupleCode,
    'memberIds': memberIds,
    'memberCount': memberCount,
    'createdByUserId': createdByUserId,
    'status': status,
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
    coupleCode: json['coupleCode'] as String?,
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
    String? coupleCode,
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
        coupleCode: coupleCode ?? this.coupleCode,
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

