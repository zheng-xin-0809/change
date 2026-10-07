import 'package:shared_preferences/shared_preferences.dart';

import '../domain/accent_color.dart';

abstract interface class AccentStore {
  Future<AccentColor> read();
  Future<void> write(AccentColor color);
}

class LocalAccentStore implements AccentStore {
  LocalAccentStore({
    SharedPreferencesAsync? preferences,
    this.key = 'accent_hex',
  }) : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  final String key;

  @override
  Future<AccentColor> read() async =>
      AccentColor.parse(await _preferences.getString(key) ?? '') ??
      AccentColor.defaultColor;

  @override
  Future<void> write(AccentColor color) =>
      _preferences.setString(key, color.hex);
}
