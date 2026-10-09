import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';

class PlanDialog extends StatefulWidget {
  const PlanDialog({
    super.key,
    required this.controller,
    this.plan,
    this.deleting = false,
  });
  final AppController controller;
  final TrainingPlan? plan;
  final bool deleting;

  @override
  State<PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<PlanDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name ?? '');
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || (!widget.deleting && !_form.currentState!.validate())) {
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      if (widget.deleting) {
        await widget.controller.deletePlan(widget.plan!.id);
      } else if (widget.plan == null) {
        await widget.controller.createPlan(_name.text);
      } else {
        await widget.controller.renamePlan(widget.plan!.id, _name.text);
      }
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final message = widget.deleting ? l.planDeleted : l.planSaved;
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
        scrollable: true,
        title: Text(
          widget.deleting
              ? l.deletePlan
              : widget.plan == null
              ? l.createPlan
              : l.renamePlan,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.deleting)
              Text(l.deletePlanBody(widget.plan!.name))
            else
              Form(
                key: _form,
                child: TextFormField(
                  key: const ValueKey('plan_name'),
                  controller: _name,
                  autofocus: true,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: l.planName,
                    hintText: l.planNameHint,
                    errorMaxLines: 3,
                  ),
                  validator: (value) {
                    try {
                      validatedPlanName(value ?? '');
                      return null;
                    } on ArgumentError {
                      return l.planNameInvalid;
                    }
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
            if (_failed) ...[
              const SizedBox(height: 12),
              Text(
                l.planChangeFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_plan'),
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('submit_plan'),
            style: widget.deleting
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: _saving ? null : _submit,
            child: Text(
              _saving
                  ? l.planSaving
                  : widget.deleting
                  ? l.deletePlan
                  : l.save,
            ),
          ),
        ],
      ),
    );
  }
}
