import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final Map<String, dynamic>? weight;
  final Map<String, dynamic>? height;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? activityLevel;
  final String? experience;
  final Map<String, dynamic>? goalWeight;
  final String? weightGoal; // 'gain', 'lose', or 'maintain'
  final List<Map<String, dynamic>>? mealTimes;
  final Map<String, dynamic>? nutritionTargets;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? onboardingCompleted;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.weight,
    this.height,
    this.gender,
    this.dateOfBirth,
    this.activityLevel,
    this.experience,
    this.goalWeight,
    this.weightGoal,
    this.mealTimes,
    this.nutritionTargets,
    this.createdAt,
    this.updatedAt,
    this.onboardingCompleted,
  });

  // Factory method to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to String
    String? safeString(dynamic value) {
      if (value == null) return null;

      try {
        if (value is String) return value;

        if (value is List) {
          if (value.isEmpty) return null;

          // Special handling for List<String>
          if (value is List<String>) {
            return value.first;
          }

          // Handle other list types
          if (value.first is String) {
            return value.first as String;
          }

          return value.first.toString();
        }

        // For any other type, convert to string
        return value.toString();
      } catch (e) {
        print('Error converting value to string: $e');
        // Return empty string as a safe default
        return '';
      }
    }

    // Helper function to safely convert to Map<String, dynamic>
    Map<String, dynamic>? safeMap(dynamic value) {
      if (value == null) return null;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return UserModel(
      id: safeString(json['id']),
      name: safeString(json['name']),
      email: safeString(json['email']),
      photoUrl: safeString(json['photoUrl']),
      weight: safeMap(json['weight']),
      height: safeMap(json['height']),
      gender: safeString(json['gender']),
      dateOfBirth: () {
        if (json['dateOfBirth'] == null) return null;

        try {
          if (json['dateOfBirth'] is String) {
            return DateTime.parse(json['dateOfBirth'] as String);
          } else if (json['dateOfBirth'] is List) {
            // Special handling for List<String>
            if (json['dateOfBirth'] is List<String>) {
              final list = json['dateOfBirth'] as List<String>;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first);
              }
            } else {
              final list = json['dateOfBirth'] as List;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first.toString());
              }
            }
          }
        } catch (e) {
          print('Error parsing dateOfBirth: $e');
        }

        // Default to a reasonable date if parsing fails
        return DateTime(2000, 1, 1);
      }(),
      activityLevel: safeString(json['activityLevel']),
      experience: safeString(json['experience']),
      goalWeight: safeMap(json['goalWeight']),
      weightGoal: safeString(json['weightGoal']),
      mealTimes: () {
        // Helper function to safely convert mealTimes
        if (json['mealTimes'] == null) return null;

        try {
          if (json['mealTimes'] is List) {
            return (json['mealTimes'] as List)
                .map((e) {
                  if (e is Map) {
                    return Map<String, dynamic>.from(e);
                  } else if (e is String) {
                    try {
                      return jsonDecode(e) as Map<String, dynamic>;
                    } catch (_) {
                      return <String, dynamic>{'time': e};
                    }
                  } else {
                    return <String, dynamic>{};
                  }
                })
                .toList();
          } else if (json['mealTimes'] is String) {
            try {
              final decoded = jsonDecode(json['mealTimes'] as String);
              if (decoded is List) {
                return decoded
                    .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                    .toList();
              }
            } catch (_) {}
          }
        } catch (e) {
          print('Error parsing mealTimes: $e');
        }

        // Default empty list if we can't parse
        return <Map<String, dynamic>>[];
      }(),
      nutritionTargets: safeMap(json['nutritionTargets']),
      createdAt: () {
        if (json['createdAt'] == null) return null;

        try {
          if (json['createdAt'] is String) {
            return DateTime.parse(json['createdAt'] as String);
          } else if (json['createdAt'] is List) {
            // Special handling for List<String>
            if (json['createdAt'] is List<String>) {
              final list = json['createdAt'] as List<String>;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first);
              }
            } else {
              final list = json['createdAt'] as List;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first.toString());
              }
            }
          }
        } catch (e) {
          print('Error parsing createdAt: $e');
        }

        return DateTime.now();
      }(),
      updatedAt: () {
        if (json['updatedAt'] == null) return null;

        try {
          if (json['updatedAt'] is String) {
            return DateTime.parse(json['updatedAt'] as String);
          } else if (json['updatedAt'] is List) {
            // Special handling for List<String>
            if (json['updatedAt'] is List<String>) {
              final list = json['updatedAt'] as List<String>;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first);
              }
            } else {
              final list = json['updatedAt'] as List;
              if (list.isNotEmpty) {
                return DateTime.parse(list.first.toString());
              }
            }
          }
        } catch (e) {
          print('Error parsing updatedAt: $e');
        }

        return DateTime.now();
      }(),
      onboardingCompleted: json['onboardingCompleted'] is bool ? json['onboardingCompleted'] as bool : json['onboardingCompleted'] == 'true',
    );
  }

  // Method to convert a UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'weight': weight,
      'height': height,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'activityLevel': activityLevel,
      'experience': experience,
      'goalWeight': goalWeight,
      'weightGoal': weightGoal,
      'mealTimes': mealTimes,
      'nutritionTargets': nutritionTargets,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
    };
  }

  // Create a copy of the UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    Map<String, dynamic>? weight,
    Map<String, dynamic>? height,
    String? gender,
    DateTime? dateOfBirth,
    String? activityLevel,
    String? experience,
    Map<String, dynamic>? goalWeight,
    String? weightGoal,
    List<Map<String, dynamic>>? mealTimes,
    Map<String, dynamic>? nutritionTargets,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      activityLevel: activityLevel ?? this.activityLevel,
      experience: experience ?? this.experience,
      goalWeight: goalWeight ?? this.goalWeight,
      weightGoal: weightGoal ?? this.weightGoal,
      mealTimes: mealTimes ?? this.mealTimes,
      nutritionTargets: nutritionTargets ?? this.nutritionTargets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
