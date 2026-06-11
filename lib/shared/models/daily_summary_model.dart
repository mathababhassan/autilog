import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Rating scale for sleep and mood
enum Rating { bad, poor, average, good, excellent }

class DailySummaryModel extends Equatable {
  final String childId;
  final DateTime date;
  final Rating sleepRating;
  final DateTime? bedtime;
  final DateTime? wakeTime;
  final Rating moodRating;
  final bool breakfastEaten;
  final bool lunchEaten;
  final bool dinnerEaten;
  final String? breakfastDetails;
  final String? lunchDetails;
  final String? dinnerDetails;
  final bool routineNormal;
  final String? notes;
  final String? createdBy;
  final String? therapistComments;
  final int? sleepHours;
  final Map<String, dynamic> customAnswers; // NEW: for dynamic question answers

  const DailySummaryModel({
    required this.childId,
    required this.date,
    required this.sleepRating,
    this.bedtime,
    this.wakeTime,
    required this.moodRating,
    required this.breakfastEaten,
    required this.lunchEaten,
    required this.dinnerEaten,
    this.breakfastDetails,   
    this.lunchDetails,      
    this.dinnerDetails,      
    required this.routineNormal,
    this.notes,
    this.createdBy,
    this.therapistComments,
    this.sleepHours,
    this.customAnswers = const {}, // Default to empty map
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'date': Timestamp.fromDate(date),
      'sleepRating': sleepRating.index,
      'bedtime': bedtime != null ? Timestamp.fromDate(bedtime!) : null,
      'wakeTime': wakeTime != null ? Timestamp.fromDate(wakeTime!) : null,
      'moodRating': moodRating.index,
      'breakfastEaten': breakfastEaten,
      'lunchEaten': lunchEaten,
      'dinnerEaten': dinnerEaten,
      'breakfastDetails': breakfastDetails,    
      'lunchDetails': lunchDetails,            
      'dinnerDetails': dinnerDetails, 
      'routineNormal': routineNormal,
      'notes': notes,
      'createdBy': createdBy,
      'therapistComments': therapistComments,
      'sleepHours': sleepHours,
      'customAnswers': customAnswers, // NEW: save dynamic answers
    };
  }

  /// Robust parser for Firestore values
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      childId: json['childId'] as String,
      date: _parseDate(json['date']) ?? DateTime.now(),
      sleepRating: Rating.values[json['sleepRating'] as int],
      bedtime: _parseDate(json['bedtime']),
      wakeTime: _parseDate(json['wakeTime']),
      moodRating: Rating.values[json['moodRating'] as int],
      breakfastEaten: json['breakfastEaten'] as bool,
      lunchEaten: json['lunchEaten'] as bool,
      dinnerEaten: json['dinnerEaten'] as bool,
      breakfastDetails: json['breakfastDetails'] as String?,   
      lunchDetails: json['lunchDetails'] as String?,        
      dinnerDetails: json['dinnerDetails'] as String?,        
      routineNormal: json['routineNormal'] as bool,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      therapistComments: json['therapistComments'] as String?,
      sleepHours: json['sleepHours'] as int?,
      customAnswers: json['customAnswers'] as Map<String, dynamic>? ?? {}, // NEW
    );
  }

  @override
  List<Object?> get props => [
        childId,
        date,
        sleepRating,
        bedtime,
        wakeTime,
        moodRating,
        breakfastEaten,
        lunchEaten,
        dinnerEaten,
        breakfastDetails,   
        lunchDetails,        
        dinnerDetails,     
        routineNormal,
        notes,
        createdBy,
        therapistComments,
        sleepHours,
        customAnswers, // NEW
      ];
}