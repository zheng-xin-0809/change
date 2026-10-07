/// Stable identifiers are persisted; translated display labels live in ARB.
enum LanguageMode { system, zh, en }

enum MealType { breakfast, preWorkout, postWorkout, other }

extension MealTypeId on MealType {
  String get id => switch (this) {
    MealType.breakfast => 'breakfast',
    MealType.preWorkout => 'pre_workout',
    MealType.postWorkout => 'post_workout',
    MealType.other => 'other',
  };
}

enum TrainingTime { afterBreakfast, beforeLunch, afterDinner, beforeDinner }

extension TrainingTimeId on TrainingTime {
  String get id => switch (this) {
    TrainingTime.afterBreakfast => 'after_breakfast',
    TrainingTime.beforeLunch => 'before_lunch',
    TrainingTime.afterDinner => 'after_dinner',
    TrainingTime.beforeDinner => 'before_dinner',
  };
}

enum BodyPart {
  back,
  cardio,
  chest,
  lowerArms,
  lowerLegs,
  neck,
  shoulders,
  upperArms,
  upperLegs,
  waist,
}

extension BodyPartId on BodyPart {
  String get id => switch (this) {
    BodyPart.lowerArms => 'lower_arms',
    BodyPart.lowerLegs => 'lower_legs',
    BodyPart.upperArms => 'upper_arms',
    BodyPart.upperLegs => 'upper_legs',
    _ => name,
  };
}

enum DayKind { training, rest }

/// Calendar dates are local dates, never UTC-midnight timestamps.
String localDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class Exercise {
  const Exercise({
    required this.id,
    required this.bodyPart,
    required this.nameZh,
    required this.nameEn,
    required this.instructionsZh,
    required this.instructionsEn,
  });
  final String id;
  final BodyPart bodyPart;
  final String nameZh;
  final String nameEn;
  final List<String> instructionsZh;
  final List<String> instructionsEn;
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    this.active = false,
  });
  final String id;
  final String name; // User input, never translated.
  final bool active;
}

class DaySchedule {
  const DaySchedule({
    required this.kind,
    this.time,
    this.bodyParts = const [],
    this.exerciseIds = const [],
  });
  final DayKind kind;
  final TrainingTime? time;
  final List<BodyPart> bodyParts;
  final List<String> exerciseIds;
}

class PlanDay {
  const PlanDay({
    required this.planId,
    required this.weekday,
    required this.schedule,
  });
  final String planId;
  final int weekday; // ISO weekday 1–7.
  final DaySchedule schedule;
}

class DayOverride {
  const DayOverride({required this.date, required this.schedule});
  final String date;
  final DaySchedule schedule;
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.foodName,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.note = '',
  });
  final String id;
  final String date;
  final MealType type;
  final String foodName;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final String note;
}

class WeightEntry {
  const WeightEntry({required this.date, required this.kilograms});
  final String date;
  final double kilograms;
}

class CheckIn {
  const CheckIn({
    required this.date,
    required this.kind,
    required this.bodyParts,
    required this.completedAt,
  });
  final String date;
  final DayKind kind;
  final List<BodyPart>
  bodyParts; // Historical snapshot, not a live plan reference.
  final DateTime completedAt;
}

class MealPhoto {
  const MealPhoto({
    required this.id,
    required this.mealEntryId,
    required this.relativePath,
  });
  final String id;
  final String mealEntryId;
  final String relativePath;
}
