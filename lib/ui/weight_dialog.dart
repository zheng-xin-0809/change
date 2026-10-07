import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';

class WeightDialog extends StatefulWidget {
  const WeightDialog({
    super.key,
    required this.controller,
    required this.date,
    this.existing,
  });
  final AppController controller;
  final String date;
  final WeightEntry? existing;
  @override
  State<WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<WeightDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _text = TextEditingController(
    text: widget.existing?.kilograms.toString() ?? '',
  );
  bool _saving = false;
  bool _failed = false;
  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.controller.saveWeight(
        WeightEntry(date: widget.date, kilograms: _parse(_text.text)!),
      );
      if (!mounted) return;
      final message = AppLocalizations.of(context).weightSaved;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(widget.existing == null ? l.recordWeight : l.editWeight),
        scrollable: true,
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.weightDialogBody),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('weight_input'),
                controller: _text,
                autofocus: true,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l.weightField,
                  hintText: l.weightHint,
                ),
                validator: (text) {
                  final value = _parse(text ?? '');
                  return value == null || !value.isFinite || value <= 0
                      ? l.weightInvalid
                      : null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              if (_failed) ...[
                const SizedBox(height: 12),
                Text(
                  l.saveFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('save_weight'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ],
      ),
    );
  }
}
