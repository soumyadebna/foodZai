import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/food_item.dart';
import '../models/daily_nutrition.dart' as nutrition;

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _foodItemsCollection = FirebaseFirestore.instance.collection('food_items');
  final CollectionReference _dailyNutritionCollection = FirebaseFirestore.instance.collection('daily_nutrition');
  final CollectionReference _waterTrackingCollection = FirebaseFirestore.instance.collection('water_tracking');

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isUserSignedIn => _auth.currentUser != null;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // User operations
  Future<void> saveUserData(UserModel user) async {
    try {
      // If user is signed in, save to Firestore
      if (isUserSignedIn) {
        await _usersCollection.doc(userId).set(user.toJson());
      }
    } catch (e) {
      debugPrint('Error saving user data to Firestore: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      // If user is signed in, get from Firestore
      if (isUserSignedIn) {
        final docSnapshot = await _usersCollection.doc(userId).get();
        if (docSnapshot.exists) {
          return UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data from Firestore: $e');
      return null;
    }
  }

  // Food item operations
  Future<void> saveFoodItem(FoodItem foodItem) async {
    try {
      if (isUserSignedIn) {
        await _foodItemsCollection
            .doc(userId)
            .collection('items')
            .add(foodItem.toJson());
      }
    } catch (e) {
      debugPrint('Error saving food item to Firestore: $e');
      rethrow;
    }
  }

  Future<List<FoodItem>> getFoodItems() async {
    try {
      if (isUserSignedIn) {
        final querySnapshot = await _foodItemsCollection
            .doc(userId)
            .collection('items')
            .get();

        return querySnapshot.docs
            .map((doc) => FoodItem.fromJson(doc.data()))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting food items from Firestore: $e');
      return [];
    }
  }

  Future<List<FoodItem>> getFoodItemsForDate(DateTime date) async {
    try {
      if (isUserSignedIn) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final querySnapshot = await _foodItemsCollection
            .doc(userId)
            .collection('items')
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .where('timestamp', isLessThanOrEqualTo: endOfDay.toIso8601String())
            .get();

        return querySnapshot.docs
            .map((doc) => FoodItem.fromJson(doc.data()))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting food items for date from Firestore: $e');
      return [];
    }
  }

  Future<void> removeFoodItem(FoodItem foodItem) async {
    try {
      if (isUserSignedIn) {
        final querySnapshot = await _foodItemsCollection
            .doc(userId)
            .collection('items')
            .where('name', isEqualTo: foodItem.name)
            .where('timestamp', isEqualTo: foodItem.timestamp.toIso8601String())
            .get();

        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Error removing food item from Firestore: $e');
      rethrow;
    }
  }

  // Daily nutrition operations
  Future<void> saveDailyNutrition(nutrition.DailyNutrition dailyNutrition) async {
    try {
      if (isUserSignedIn) {
        final dateStr = '${dailyNutrition.date.year}-${dailyNutrition.date.month}-${dailyNutrition.date.day}';
        await _dailyNutritionCollection
            .doc(userId)
            .collection('days')
            .doc(dateStr)
            .set(dailyNutrition.toJson());
      }
    } catch (e) {
      debugPrint('Error saving daily nutrition to Firestore: $e');
      rethrow;
    }
  }

  Future<nutrition.DailyNutrition?> getDailyNutrition(DateTime date) async {
    try {
      if (isUserSignedIn) {
        final dateStr = '${date.year}-${date.month}-${date.day}';
        final docSnapshot = await _dailyNutritionCollection
            .doc(userId)
            .collection('days')
            .doc(dateStr)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          return nutrition.DailyNutrition.fromJson(docSnapshot.data()! as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting daily nutrition from Firestore: $e');
      return null;
    }
  }

  // Water tracking operations
  Future<void> setWaterIntake(DateTime date, int intake) async {
    try {
      if (isUserSignedIn) {
        final dateStr = '${date.year}-${date.month}-${date.day}';
        await _waterTrackingCollection
            .doc(userId)
            .collection('days')
            .doc(dateStr)
            .set({'intake': intake});
      }
    } catch (e) {
      debugPrint('Error saving water intake to Firestore: $e');
      rethrow;
    }
  }

  Future<int> getWaterIntake(DateTime date) async {
    try {
      if (isUserSignedIn) {
        final dateStr = '${date.year}-${date.month}-${date.day}';
        final docSnapshot = await _waterTrackingCollection
            .doc(userId)
            .collection('days')
            .doc(dateStr)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()! as Map<String, dynamic>;
          return data['intake'] as int? ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting water intake from Firestore: $e');
      return 0;
    }
  }

  Future<void> setWaterGoal(int goal) async {
    try {
      if (isUserSignedIn) {
        await _waterTrackingCollection
            .doc(userId)
            .set({'goal': goal});
      }
    } catch (e) {
      debugPrint('Error saving water goal to Firestore: $e');
      rethrow;
    }
  }

  Future<int> getWaterGoal() async {
    try {
      if (isUserSignedIn) {
        final docSnapshot = await _waterTrackingCollection
            .doc(userId)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()! as Map<String, dynamic>;
          return data['goal'] as int? ?? 12;
        }
      }
      return 12; // Default water goal
    } catch (e) {
      debugPrint('Error getting water goal from Firestore: $e');
      return 12;
    }
  }
}
