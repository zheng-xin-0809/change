import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

abstract interface class LanguageStore {
  Future<LanguageMode> read();
  Future<void> write(LanguageMode mode);
}

class LocalLanguageStore implements LanguageStore {
  LocalLanguageStore({
    SharedPreferencesAsync? preferences,
    this.key = 'locale_mode',
  }) : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  final String key;

  @override
  Future<LanguageMode> read() async {
    final saved = await _preferences.getString(key);
    return LanguageMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => LanguageMode.system,
    );
  }

  @override
  Future<void> write(LanguageMode mode) =>
      _preferences.setString(key, mode.name);
}
