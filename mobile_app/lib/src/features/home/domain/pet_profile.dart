class PetProfile {
  final String name;
  final String imagePath; // Local path or Asset path
  final String featuredImagePath; // New: Featured large photo
  final String age; // "나의" -> Age
  final String weight;
  final String breed;
  final String heartRate;

  // New: Favorites
  final String favoriteCourse;
  final String favoriteFood;
  final String favoritePlace;

  // New: Favorite Images
  final String favoriteCourseImage;
  final String favoriteFoodImage;
  final String favoritePlaceImage;

  PetProfile({
    required this.name,
    required this.imagePath,
    required this.featuredImagePath,
    required this.age,
    required this.weight,
    required this.breed,
    required this.heartRate,
    required this.favoriteCourse,
    required this.favoriteFood,
    required this.favoritePlace,
    required this.favoriteCourseImage,
    required this.favoriteFoodImage,
    required this.favoritePlaceImage,
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
      favoriteCourse: "Han River Park",
      favoriteFood: "Chicken Breast",
      favoritePlace: "Sofa",
      favoriteCourseImage: "assets/images/fav_course.png",
      favoriteFoodImage: "assets/images/fav_food.png",
      favoritePlaceImage: "assets/images/fav_place.png",
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
      'favoriteCourse': favoriteCourse,
      'favoriteFood': favoriteFood,
      'favoritePlace': favoritePlace,
      'favoriteCourseImage': favoriteCourseImage,
      'favoriteFoodImage': favoriteFoodImage,
      'favoritePlaceImage': favoritePlaceImage,
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
      favoriteCourse: json['favoriteCourse'] ?? "Han River Park",
      favoriteFood: json['favoriteFood'] ?? "Chicken Breast",
      favoritePlace: json['favoritePlace'] ?? "Sofa",
      favoriteCourseImage:
          json['favoriteCourseImage'] ?? "assets/images/fav_course.png",
      favoriteFoodImage:
          json['favoriteFoodImage'] ?? "assets/images/fav_food.png",
      favoritePlaceImage:
          json['favoritePlaceImage'] ?? "assets/images/fav_place.png",
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
    String? favoriteCourse,
    String? favoriteFood,
    String? favoritePlace,
    String? favoriteCourseImage,
    String? favoriteFoodImage,
    String? favoritePlaceImage,
  }) {
    return PetProfile(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      featuredImagePath: featuredImagePath ?? this.featuredImagePath,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      breed: breed ?? this.breed,
      heartRate: heartRate ?? this.heartRate,
      favoriteCourse: favoriteCourse ?? this.favoriteCourse,
      favoriteFood: favoriteFood ?? this.favoriteFood,
      favoritePlace: favoritePlace ?? this.favoritePlace,
      favoriteCourseImage: favoriteCourseImage ?? this.favoriteCourseImage,
      favoriteFoodImage: favoriteFoodImage ?? this.favoriteFoodImage,
      favoritePlaceImage: favoritePlaceImage ?? this.favoritePlaceImage,
    );
  }
}
