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
  Future<void> close() async {}
}
