class Photo {
  final String id;
  final String path;
  final String? remoteUrl;
  final String? storagePath;
  final String? coupleId;
  final String? authorUserId;
  final String? authorName;
  final DateTime uploadDate;
  final String? caption;
  final DateTime? updatedAt;

  Photo({
    required this.id,
    required this.path,
    this.remoteUrl,
    this.storagePath,
    this.coupleId,
    this.authorUserId,
    this.authorName,
    required this.uploadDate,
    this.caption,
    this.updatedAt,
  });

  bool get hasLocalPath => path.trim().isNotEmpty;
  bool get hasRemoteUrl => remoteUrl?.trim().isNotEmpty == true;
  String get posterName => authorName?.trim().isNotEmpty == true ? authorName!.trim() : 'Người ấy';

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'remoteUrl': remoteUrl,
    'storagePath': storagePath,
    'coupleId': coupleId,
    'authorUserId': authorUserId,
    'authorName': authorName,
    'uploadDate': uploadDate.toIso8601String(),
    'caption': caption,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'path': '',
    'remoteUrl': remoteUrl,
    'storagePath': storagePath,
    'coupleId': coupleId,
    'authorUserId': authorUserId,
    'authorName': authorName,
    'uploadDate': uploadDate,
    'caption': caption,
    'updatedAt': updatedAt,
  };

  // Create from JSON
  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'],
    path: json['path'] as String? ?? '',
    remoteUrl: json['remoteUrl'] as String?,
    storagePath: json['storagePath'] as String?,
    coupleId: json['coupleId'] as String?,
    authorUserId: json['authorUserId'] as String?,
    authorName: json['authorName'] as String?,
    uploadDate: _parseDateTime(json['uploadDate']) ?? DateTime.now(),
    caption: json['caption'],
    updatedAt: _parseDateTime(json['updatedAt']),
  );

  // Copy with method
  Photo copyWith({
    String? id,
    String? path,
    String? remoteUrl,
    String? storagePath,
    String? coupleId,
    String? authorUserId,
    String? authorName,
    DateTime? uploadDate,
    String? caption,
    DateTime? updatedAt,
  }) =>
      Photo(
        id: id ?? this.id,
        path: path ?? this.path,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        storagePath: storagePath ?? this.storagePath,
        coupleId: coupleId ?? this.coupleId,
        authorUserId: authorUserId ?? this.authorUserId,
        authorName: authorName ?? this.authorName,
        uploadDate: uploadDate ?? this.uploadDate,
        caption: caption ?? this.caption,
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

    final dynamic millisecondsSinceEpoch = (value as dynamic).millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }

    return null;
  }
}

