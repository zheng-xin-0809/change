import 'package:flutter/widgets.dart';

import '../data/language_store.dart';
import '../data/accent_store.dart';
import '../domain/accent_color.dart';
import '../data/local_record_store.dart';
import '../domain/models.dart';
import '../services/calculation_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.languageStore,
    required this.records,
    required this.accentStore,
    this.calculation = const PendingCalculationService(),
  });
  final LanguageStore languageStore;
  final RecordStore records;
  final AccentStore accentStore;
  AccentColor accentColor = AccentColor.defaultColor;
  bool savingAccent = false;
  final CalculationService calculation;
  LanguageMode languageMode = LanguageMode.system;
  WeightEntry? latest;
  bool ready = false;
  bool loading = false;
  bool startupFailed = false;
  bool savingLanguage = false;

  Locale? get locale => switch (languageMode) {
    LanguageMode.system => null,
    LanguageMode.zh => const Locale('zh'),
    LanguageMode.en => const Locale('en'),
  };

  Future<void> initialize() async {
    if (loading) return;
    loading = true;
    startupFailed = false;
    notifyListeners();
    try {
      languageMode = await languageStore.read();
      accentColor = await accentStore.read();
      await records.initialize();
      latest = await records.latestWeight();
      ready = true;
    } catch (_) {
      startupFailed = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(LanguageMode mode) async {
    if (savingLanguage || mode == languageMode) return;
    savingLanguage = true;
    notifyListeners();
    try {
      // Commit the preference before presenting a successful language change.
      await languageStore.write(mode);
      languageMode = mode;
    } finally {
      savingLanguage = false;
      notifyListeners();
    }
  }

  Future<void> saveWeight(WeightEntry entry) async {
    await records.saveWeight(entry);
    if (latest == null || entry.date.compareTo(latest!.date) >= 0) {
      latest = entry;
    }
    notifyListeners();
  }

  Future<void> setAccent(AccentColor color) async {
    if (savingAccent || color == accentColor) return;
    savingAccent = true;
    notifyListeners();
    try {
      await accentStore.write(color);
      accentColor = color;
    } finally {
      savingAccent = false;
      notifyListeners();
    }
  }
}
