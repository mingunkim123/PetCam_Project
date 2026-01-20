class PetProfile {
  final String name;
  final String imagePath; // Local path or Asset path
  final String featuredImagePath; // New: Featured large photo
  final String age; // "나의" -> Age
  final String weight;
  final String breed;
  final String heartRate;

  PetProfile({
    required this.name,
    required this.imagePath,
    required this.featuredImagePath,
    required this.age,
    required this.weight,
    required this.breed,
    required this.heartRate,
  });

  // Default empty profile
  factory PetProfile.empty() {
    return PetProfile(
      name: "My Pet",
      imagePath: "",
      featuredImagePath: "",
      age: "0",
      weight: "0kg",
      breed: "Unknown",
      heartRate: "0 BPM",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'featuredImagePath': featuredImagePath,
      'age': age,
      'weight': weight,
      'breed': breed,
      'heartRate': heartRate,
    };
  }

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      name: json['name'] ?? "My Pet",
      imagePath: json['imagePath'] ?? "",
      featuredImagePath: json['featuredImagePath'] ?? "",
      age: json['age'] ?? "0",
      weight: json['weight'] ?? "0kg",
      breed: json['breed'] ?? "Unknown",
      heartRate: json['heartRate'] ?? "0 BPM",
    );
  }

  PetProfile copyWith({
    String? name,
    String? imagePath,
    String? featuredImagePath,
    String? age,
    String? weight,
    String? breed,
    String? heartRate,
  }) {
    return PetProfile(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      featuredImagePath: featuredImagePath ?? this.featuredImagePath,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      breed: breed ?? this.breed,
      heartRate: heartRate ?? this.heartRate,
    );
  }
}
