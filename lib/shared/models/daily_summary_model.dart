import 'package:cloud_firestore/cloud_firestore.dart';

class DailySummary {
  final String id;
  final String parentId;
  final String childId;
  final DateTime date;
  
  // Section 1: Sleep
  final String sleepQuality; // 'Bad', 'Poor', 'Average', 'Good', 'Excellent'
  final String? bedtime;  // Store as string like "22:00" (10:00 PM)
  final String? wakeTime; // Store as string like "06:30" (6:30 AM)
  final String? sleepDetails;
  
  // Section 2: Morning Mood
  final String morningMood; // 'Bad', 'Poor', 'Average', 'Good', 'Excellent'
  
  // Section 3: Meals
  final bool breakfastEaten;
  final bool lunchEaten;
  final bool dinnerEaten;
  final String? breakfastDetails;
  final String? lunchDetails;
  final String? dinnerDetails;
  
  // Section 4: Routine
  final bool isRoutineNormal;
  
  // TODO: Future feature - Therapist custom questions
  // Will be implemented in a later sprint when therapist review system is built
  
  final DateTime createdAt;
  final DateTime updatedAt;

  DailySummary({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.date,
    required this.sleepQuality,
    this.bedtime,
    this.wakeTime,
    this.sleepDetails,
    required this.morningMood,
    required this.breakfastEaten,
    required this.lunchEaten,
    required this.dinnerEaten,
    this.breakfastDetails,
    this.lunchDetails,
    this.dinnerDetails,
    required this.isRoutineNormal,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'date': Timestamp.fromDate(date),
      'sleepQuality': sleepQuality,
      'bedtime': bedtime,
      'wakeTime': wakeTime,
      'sleepDetails': sleepDetails,
      'morningMood': morningMood,
      'breakfastEaten': breakfastEaten,
      'lunchEaten': lunchEaten,
      'dinnerEaten': dinnerEaten,
      'breakfastDetails': breakfastDetails,
      'lunchDetails': lunchDetails,
      'dinnerDetails': dinnerDetails,
      'isRoutineNormal': isRoutineNormal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map, String id) {
    return DailySummary(
      id: id,
      parentId: map['parentId'] as String,
      childId: map['childId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      sleepQuality: map['sleepQuality'] as String? ?? 'Average',
      bedtime: map['bedtime'] as String?,
      wakeTime: map['wakeTime'] as String?,
      sleepDetails: map['sleepDetails'] as String?,
      morningMood: map['morningMood'] as String? ?? 'Average',
      breakfastEaten: map['breakfastEaten'] as bool? ?? false,
      lunchEaten: map['lunchEaten'] as bool? ?? false,
      dinnerEaten: map['dinnerEaten'] as bool? ?? false,
      breakfastDetails: map['breakfastDetails'] as String?,
      lunchDetails: map['lunchDetails'] as String?,
      dinnerDetails: map['dinnerDetails'] as String?,
      isRoutineNormal: map['isRoutineNormal'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}