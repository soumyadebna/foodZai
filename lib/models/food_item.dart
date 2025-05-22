class FoodItem {
  final String name;
  final String imageUrl;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;
  final DateTime timestamp;
  final String portion;
  final int confidence;
  final String description;

  FoodItem({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.timestamp,
    this.portion = 'Standard serving',
    this.confidence = 100,
    this.description = '',
  });

  // Factory method to create a FoodItem from JSON
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      mealType: json['mealType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      portion: json.containsKey('portion') ? json['portion'] as String : 'Standard serving',
      confidence: json.containsKey('confidence') ? json['confidence'] as int : 100,
      description: json.containsKey('description') ? json['description'] as String : '',
    );
  }

  // Method to convert a FoodItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'timestamp': timestamp.toIso8601String(),
      'portion': portion,
      'confidence': confidence,
      'description': description,
    };
  }
}


