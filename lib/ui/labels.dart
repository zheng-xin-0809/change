import '../domain/models.dart';
import '../l10n/app_localizations.dart';

String mealLabel(AppLocalizations l, MealType type) => switch (type) {
  MealType.breakfast => l.breakfast,
  MealType.preWorkout => l.preWorkout,
  MealType.postWorkout => l.postWorkout,
  MealType.other => l.otherMeal,
};
String timeLabel(AppLocalizations l, TrainingTime time) => switch (time) {
  TrainingTime.afterBreakfast => l.afterBreakfast,
  TrainingTime.beforeLunch => l.beforeLunch,
  TrainingTime.afterDinner => l.afterDinner,
  TrainingTime.beforeDinner => l.beforeDinner,
};
String bodyPartLabel(AppLocalizations l, BodyPart part) => switch (part) {
  BodyPart.back => l.bodyBack,
  BodyPart.cardio => l.bodyCardio,
  BodyPart.chest => l.bodyChest,
  BodyPart.lowerArms => l.bodyLowerArms,
  BodyPart.lowerLegs => l.bodyLowerLegs,
  BodyPart.neck => l.bodyNeck,
  BodyPart.shoulders => l.bodyShoulders,
  BodyPart.upperArms => l.bodyUpperArms,
  BodyPart.upperLegs => l.bodyUpperLegs,
  BodyPart.waist => l.bodyWaist,
};
