class Couple {
  final String person1Name;
  final String person2Name;
  final DateTime anniversaryDate;
  final String? couplePhotoPath;

  Couple({
    required this.person1Name,
    required this.person2Name,
    required this.anniversaryDate,
    this.couplePhotoPath,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'person1Name': person1Name,
    'person2Name': person2Name,
    'anniversaryDate': anniversaryDate.toIso8601String(),
    'couplePhotoPath': couplePhotoPath,
  };

  // Create from JSON
  factory Couple.fromJson(Map<String, dynamic> json) => Couple(
    person1Name: json['person1Name'],
    person2Name: json['person2Name'],
    anniversaryDate: DateTime.parse(json['anniversaryDate']),
    couplePhotoPath: json['couplePhotoPath'],
  );

  // Copy with method
  Couple copyWith({
    String? person1Name,
    String? person2Name,
    DateTime? anniversaryDate,
    String? couplePhotoPath,
  }) =>
      Couple(
        person1Name: person1Name ?? this.person1Name,
        person2Name: person2Name ?? this.person2Name,
        anniversaryDate: anniversaryDate ?? this.anniversaryDate,
        couplePhotoPath: couplePhotoPath ?? this.couplePhotoPath,
      );
}

