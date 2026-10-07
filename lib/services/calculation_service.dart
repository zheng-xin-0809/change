import '../domain/models.dart';

class MacroTargets {
  const MacroTargets({
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });
  final double carbsG;
  final double proteinG;
  final double fatG;
}

/// A future formula supplies its own explicit input contract. Do not infer
/// required personal fields or equations before the user specifies them.
abstract interface class CalculationInput {}

class CalculationResult {
  const CalculationResult({required this.daily, required this.meals});
  final MacroTargets daily;
  final Map<MealType, MacroTargets> meals;
}

/// Both the formula and meal allocation are replaceable independently of UI/data.
abstract interface class CalculationService {
  bool get isAvailable;
  Future<CalculationResult> calculate(
    CalculationInput input,
    TrainingTime time,
  );
}

class CalculationNotConfigured implements Exception {}

class PendingCalculationService implements CalculationService {
  const PendingCalculationService();
  @override
  bool get isAvailable => false;
  @override
  Future<CalculationResult> calculate(
    CalculationInput input,
    TrainingTime time,
  ) async {
    throw CalculationNotConfigured();
  }
}
