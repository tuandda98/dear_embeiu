class AccountInvite {
  const AccountInvite({
    required this.code,
    required this.userId,
    required this.displayName,
    this.coupleId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String code;
  final String userId;
  final String displayName;
  final String? coupleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'coupleId': coupleId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AccountInvite.fromJson(String code, Map<String, dynamic> json) {
    return AccountInvite(
      code: code,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      coupleId: json['coupleId'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
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

