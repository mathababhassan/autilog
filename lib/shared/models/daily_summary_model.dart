import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Sentinel for nullable copyWith fields
const _clear = Object();

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
  final bool routineNormal;
  final bool? hadScreenTime;
  final double? screenTimeHours;
  final bool medicationTaken;
  final String? notes;
  final String? createdBy;
  final String? therapistComments;
  final int? sleepHours;

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
    required this.routineNormal,
    this.hadScreenTime,
    this.screenTimeHours,
    required this.medicationTaken,
    this.notes,
    this.createdBy,
    this.therapistComments,
    this.sleepHours,
  });

  DailySummaryModel copyWith({
    String? childId,
    DateTime? date,
    Rating? sleepRating,
    Object? bedtime = _clear,
    Object? wakeTime = _clear,
    Rating? moodRating,
    bool? breakfastEaten,
    bool? lunchEaten,
    bool? dinnerEaten,
    bool? routineNormal,
    Object? hadScreenTime = _clear,
    Object? screenTimeHours = _clear,
    bool? medicationTaken,
    Object? notes = _clear,
    Object? createdBy = _clear,
    Object? therapistComments = _clear,
    Object? sleepHours = _clear,
  }) {
    return DailySummaryModel(
      childId: childId ?? this.childId,
      date: date ?? this.date,
      sleepRating: sleepRating ?? this.sleepRating,
      bedtime: bedtime == _clear ? this.bedtime : bedtime as DateTime?,
      wakeTime: wakeTime == _clear ? this.wakeTime : wakeTime as DateTime?,
      moodRating: moodRating ?? this.moodRating,
      breakfastEaten: breakfastEaten ?? this.breakfastEaten,
      lunchEaten: lunchEaten ?? this.lunchEaten,
      dinnerEaten: dinnerEaten ?? this.dinnerEaten,
      routineNormal: routineNormal ?? this.routineNormal,
      hadScreenTime:
          hadScreenTime == _clear ? this.hadScreenTime : hadScreenTime as bool?,
      screenTimeHours: screenTimeHours == _clear
          ? this.screenTimeHours
          : screenTimeHours as double?,
      medicationTaken: medicationTaken ?? this.medicationTaken,
      notes: notes == _clear ? this.notes : notes as String?,
      createdBy: createdBy == _clear ? this.createdBy : createdBy as String?,
      therapistComments: therapistComments == _clear
          ? this.therapistComments
          : therapistComments as String?,
      sleepHours: sleepHours == _clear ? this.sleepHours : sleepHours as int?,
    );
  }

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
      'routineNormal': routineNormal,
      'hadScreenTime': hadScreenTime,
      'screenTimeHours': screenTimeHours,
      'medicationTaken': medicationTaken,
      'notes': notes,
      'createdBy': createdBy,
      'therapistComments': therapistComments,
      'sleepHours': sleepHours,
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
      routineNormal: json['routineNormal'] as bool,
      hadScreenTime: json['hadScreenTime'] as bool?,
      screenTimeHours: (json['screenTimeHours'] as num?)?.toDouble(),
      medicationTaken: json['medicationTaken'] as bool,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      therapistComments: json['therapistComments'] as String?,
      sleepHours: json['sleepHours'] as int?,
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
        routineNormal,
        hadScreenTime,
        screenTimeHours,
        medicationTaken,
        notes,
        createdBy,
        therapistComments,
        sleepHours,
      ];
}