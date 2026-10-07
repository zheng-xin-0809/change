/// An opaque, persisted RGB color. UI labels live in the ARB resources.
class AccentColor {
  const AccentColor._(this.rgb);
  static const defaultColor = AccentColor._(0x166A58);
  final int rgb;
  int get red => (rgb >> 16) & 0xFF;
  int get green => (rgb >> 8) & 0xFF;
  int get blue => rgb & 0xFF;
  int get argb => 0xFF000000 | rgb;
  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static AccentColor? fromRgb(int red, int green, int blue) {
    if ([red, green, blue].any((value) => value < 0 || value > 255)) {
      return null;
    }
    return AccentColor._((red << 16) | (green << 8) | blue);
  }

  static AccentColor? parse(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(normalized)) return null;
    return AccentColor._(
      int.parse(normalized.replaceFirst('#', ''), radix: 16),
    );
  }

  @override
  bool operator ==(Object other) => other is AccentColor && rgb == other.rgb;
  @override
  int get hashCode => rgb.hashCode;
}
