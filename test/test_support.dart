import 'package:fit_notes/data/language_store.dart';
import 'package:fit_notes/data/accent_store.dart';
import 'package:fit_notes/domain/accent_color.dart';
import 'package:fit_notes/data/local_record_store.dart';
import 'package:fit_notes/domain/models.dart';

class MemoryLanguageStore implements LanguageStore {
  LanguageMode mode = LanguageMode.system;
  bool failWrite = false;
  @override
  Future<LanguageMode> read() async => mode;
  @override
  Future<void> write(LanguageMode value) async {
    if (failWrite) throw StateError('Simulated unavailable storage');
    mode = value;
  }
}

class MemoryAccentStore implements AccentStore {
  AccentColor color = AccentColor.defaultColor;
  bool failWrite = false;

  @override
  Future<AccentColor> read() async => color;

  @override
  Future<void> write(AccentColor value) async {
    if (failWrite) throw StateError('Simulated unavailable storage');
    color = value;
  }
}

class MemoryRecordStore implements RecordStore {
  final Map<String, WeightEntry> weights = {};
  List<TrainingPlan> savedPlans = [];
  int _nextPlanId = 0;
  bool failPlans = false;
  bool failSave = false;
  bool failInitialize = false;
  @override
  Future<void> initialize() async {
    if (failInitialize) throw StateError('Unavailable storage');
  }

  @override
  Future<WeightEntry?> latestWeight() async {
    if (weights.isEmpty) return null;
    return weights[(weights.keys.toList()..sort()).last];
  }

  @override
  Future<WeightEntry?> weightFor(String date) async => weights[date];
  @override
  Future<void> saveWeight(WeightEntry entry) async {
    if (failSave) throw StateError('Storage write failed');
    weights[entry.date] = entry;
  }

  @override
  Future<List<TrainingPlan>> plans() async => List.of(savedPlans);

  void _checkPlanWrite() {
    if (failPlans) throw StateError('Plan storage unavailable');
  }

  @override
  Future<List<TrainingPlan>> createPlan(String name) async {
    _checkPlanWrite();
    savedPlans.add(
      TrainingPlan(
        id: 'plan_${_nextPlanId++}',
        name: validatedPlanName(name),
        active: !savedPlans.any((plan) => plan.active),
      ),
    );
    return plans();
  }

  @override
  Future<List<TrainingPlan>> renamePlan(String id, String name) async {
    _checkPlanWrite();
    final normalized = validatedPlanName(name);
    savedPlans = savedPlans
        .map(
          (plan) => plan.id == id
              ? TrainingPlan(id: id, name: normalized, active: plan.active)
              : plan,
        )
        .toList();
    return plans();
  }

  @override
  Future<List<TrainingPlan>> activatePlan(String id) async {
    _checkPlanWrite();
    savedPlans = savedPlans
        .map(
          (plan) =>
              TrainingPlan(id: plan.id, name: plan.name, active: plan.id == id),
        )
        .toList();
    return plans();
  }

  @override
  Future<List<TrainingPlan>> deletePlan(String id) async {
    _checkPlanWrite();
    savedPlans.removeWhere((plan) => plan.id == id);
    if (savedPlans.isNotEmpty && !savedPlans.any((plan) => plan.active)) {
      final first = savedPlans.first;
      savedPlans[0] = TrainingPlan(
        id: first.id,
        name: first.name,
        active: true,
      );
    }
    return plans();
  }

  @override
  Future<void> close() async {}
}
