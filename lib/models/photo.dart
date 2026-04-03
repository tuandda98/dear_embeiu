class Photo {
  final String id;
  final String path;
  final DateTime uploadDate;
  final String? caption;

  Photo({
    required this.id,
    required this.path,
    required this.uploadDate,
    this.caption,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'uploadDate': uploadDate.toIso8601String(),
    'caption': caption,
  };

  // Create from JSON
  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'],
    path: json['path'],
    uploadDate: DateTime.parse(json['uploadDate']),
    caption: json['caption'],
  );

  // Copy with method
  Photo copyWith({
    String? id,
    String? path,
    DateTime? uploadDate,
    String? caption,
  }) =>
      Photo(
        id: id ?? this.id,
        path: path ?? this.path,
        uploadDate: uploadDate ?? this.uploadDate,
        caption: caption ?? this.caption,
      );
}

