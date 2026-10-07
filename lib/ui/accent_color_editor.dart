import 'package:flutter/material.dart';

import '../domain/accent_color.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';

class AccentColorEditor extends StatefulWidget {
  const AccentColorEditor({super.key, required this.controller});
  final AppController controller;
  @override
  State<AccentColorEditor> createState() => _AccentColorEditorState();
}

class _AccentColorEditorState extends State<AccentColorEditor> {
  late int _red = widget.controller.accentColor.red;
  late int _green = widget.controller.accentColor.green;
  late int _blue = widget.controller.accentColor.blue;
  late final TextEditingController _hex = TextEditingController(
    text: widget.controller.accentColor.hex,
  );
  String? _error;

  AccentColor get _color => AccentColor.fromRgb(_red, _green, _blue)!;
  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setRgb({int? red, int? green, int? blue}) {
    setState(() {
      _red = red ?? _red;
      _green = green ?? _green;
      _blue = blue ?? _blue;
      _hex.text = _color.hex;
      _error = null;
    });
  }

  void _setHex(String value) {
    final parsed = AccentColor.parse(value);
    setState(() {
      _error = parsed == null
          ? AppLocalizations.of(context).accentHexInvalid
          : null;
      if (parsed != null) {
        _red = parsed.red;
        _green = parsed.green;
        _blue = parsed.blue;
      }
    });
  }

  Future<void> _save() async {
    if (_error != null) return;
    try {
      await widget.controller.setAccent(_color);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).accentSaveFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = Color(_color.argb);
    return AlertDialog(
      title: Text(l.accentTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const ValueKey('accent_preview'),
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                l.accentPreview,
                style: TextStyle(color: textColor(color)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('accent_hex'),
              controller: _hex,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l.accentHex,
                errorText: _error,
              ),
              onChanged: _setHex,
            ),
            const SizedBox(height: 16),
            for (final item in [
              (l.accentRed, _red, (int value) => _setRgb(red: value), 'red'),
              (
                l.accentGreen,
                _green,
                (int value) => _setRgb(green: value),
                'green',
              ),
              (
                l.accentBlue,
                _blue,
                (int value) => _setRgb(blue: value),
                'blue',
              ),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.$1}: ${item.$2}'),
                  Slider(
                    key: ValueKey('accent_${item.$4}'),
                    value: item.$2.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (value) => item.$3(value.round()),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('save_accent'),
          onPressed: widget.controller.savingAccent ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}

Color textColor(Color color) =>
    color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
