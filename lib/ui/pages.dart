import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';
import 'labels.dart';
import 'weight_dialog.dart';
import 'accent_color_editor.dart';
import 'plan_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  void _go(int value) => setState(() => _index = value);
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.homeTitle,
      l.plansTitle,
      l.dietTitle,
      l.calendarTitle,
      l.settingsTitle,
    ];
    final labels = [
      l.navHome,
      l.navPlans,
      l.navDiet,
      l.navCalendar,
      l.navSettings,
    ];
    const icons = [
      Icons.home_outlined,
      Icons.fitness_center,
      Icons.restaurant_outlined,
      Icons.calendar_month_outlined,
      Icons.settings_outlined,
    ];
    final content = switch (_index) {
      0 => HomePage(controller: widget.controller, onNavigate: _go),
      1 => PlansPage(controller: widget.controller),
      2 => DietPage(controller: widget.controller),
      3 => const CalendarPage(),
      _ => SettingsPage(controller: widget.controller),
    };
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(titles[_index])),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: content,
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 84,
          destinations: List.generate(
            labels.length,
            (i) => NavigationDestination(
              key: ValueKey('nav_$i'),
              icon: Icon(icons[i]),
              label: labels[i],
            ),
          ),
        ),
      ),
    );
  }
}

class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
    ],
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

String dateLabel(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(AppLocalizations.of(context).localeName).format(date);
String weightLabel(BuildContext context, double value) {
  final l = AppLocalizations.of(context);
  return l.weightValue(NumberFormat('0.##', l.localeName).format(value));
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });
  final AppController controller;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final weight = controller.latest;
    return PageList(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel(context, DateTime.now()),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              Text(
                l.homeGreeting,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l.homeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.offline_bolt_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(l.offlineLabel),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l.latestWeight,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                weight == null
                    ? l.noWeight
                    : weightLabel(context, weight.kilograms),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (weight != null) ...[
                const SizedBox(height: 8),
                Text(
                  l.recordedOn(dateLabel(context, DateTime.parse(weight.date))),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('home_weight'),
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.add),
                label: Text(l.openDiet),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => onNavigate(1),
                icon: const Icon(Icons.fitness_center),
                label: Text(l.openPlans),
              ),
            ],
          ),
        ),
        InfoCard(
          icon: Icons.spa_outlined,
          title: l.foundationTitle,
          body: l.foundationBody,
        ),
        if (controller.activePlan case final plan?)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.currentPlan,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  plan.name,
                  key: const ValueKey('home_active_plan'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.controller});
  final AppController controller;

  void _edit(
    BuildContext context, {
    TrainingPlan? plan,
    bool deleting = false,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PlanDialog(controller: controller, plan: plan, deleting: deleting),
    );
  }

  Future<void> _activate(BuildContext context, TrainingPlan plan) async {
    try {
      await controller.activatePlan(plan.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).planActivated(plan.name)),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).planChangeFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageList(
      children: [
        FilledButton.icon(
          key: const ValueKey('create_plan'),
          onPressed: controller.savingPlan ? null : () => _edit(context),
          icon: const Icon(Icons.add),
          label: Text(l.createPlan),
        ),
        Text(l.plansHelp),
        if (controller.savingPlan)
          Semantics(
            label: l.planSaving,
            child: const LinearProgressIndicator(),
          ),
        if (controller.plans.isEmpty)
          InfoCard(
            icon: Icons.fitness_center,
            title: l.noPlansTitle,
            body: l.noPlansBody,
          ),
        for (final plan in controller.plans)
          SectionCard(
            key: ValueKey('plan_${plan.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (plan.active)
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      Text(l.currentPlan),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!plan.active)
                      OutlinedButton(
                        key: ValueKey('activate_${plan.id}'),
                        onPressed: controller.savingPlan
                            ? null
                            : () => _activate(context, plan),
                        child: Text(l.usePlan),
                      ),
                    IconButton(
                      key: ValueKey('rename_${plan.id}'),
                      onPressed: controller.savingPlan
                          ? null
                          : () => _edit(context, plan: plan),
                      tooltip: l.renamePlan,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      key: ValueKey('delete_${plan.id}'),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: controller.savingPlan
                          ? null
                          : () => _edit(context, plan: plan, deleting: true),
                      tooltip: l.deletePlan,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.trainingSlots,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(l.planScheduleLater),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in TrainingTime.values)
                    Chip(label: Text(timeLabel(l, time))),
                ],
              ),
            ],
          ),
        ),
        InfoCard(
          icon: Icons.menu_book_outlined,
          title: l.bodyPartsTitle,
          body: l.exercisesLater,
        ),
      ],
    );
  }
}

class DietPage extends StatelessWidget {
  const DietPage({super.key, required this.controller});
  final AppController controller;

  Future<void> _record(BuildContext context) async {
    final date = localDateKey(DateTime.now());
    try {
      final existing = await controller.records.weightFor(date);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WeightDialog(
          controller: controller,
          date: date,
          existing: existing,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).loadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final weight = controller.latest;
    return PageList(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.weightTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                weight == null
                    ? l.noWeight
                    : weightLabel(context, weight.kilograms),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (weight != null) ...[
                const SizedBox(height: 8),
                Text(
                  l.recordedOn(dateLabel(context, DateTime.parse(weight.date))),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('record_weight'),
                onPressed: () => _record(context),
                icon: const Icon(Icons.add),
                label: Text(
                  weight?.date == localDateKey(DateTime.now())
                      ? l.editWeight
                      : l.recordWeight,
                ),
              ),
            ],
          ),
        ),
        Text(l.dailyMeals, style: Theme.of(context).textTheme.titleLarge),
        for (final meal in MealType.values)
          SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.restaurant_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealLabel(l, meal),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(l.mealComingSoon),
                    ],
                  ),
                ),
              ],
            ),
          ),
        InfoCard(
          icon: Icons.calculate_outlined,
          title: l.calculationTitle,
          body: l.calculationPending,
        ),
      ],
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageList(
      children: [
        SectionCard(
          child: CalendarDatePicker(
            initialDate: _selected,
            currentDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100, 12, 31),
            onDateChanged: (date) => setState(() => _selected = date),
          ),
        ),
        InfoCard(
          icon: Icons.event_available_outlined,
          title: dateLabel(context, _selected),
          body: l.noCheckIns,
        ),
        Text(l.calendarBody, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageList(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.languageTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButton<LanguageMode>(
                key: const ValueKey('language_selector'),
                value: controller.languageMode,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: LanguageMode.system,
                    child: Text(l.languageSystem),
                  ),
                  DropdownMenuItem(
                    value: LanguageMode.zh,
                    child: Text(l.languageChinese),
                  ),
                  DropdownMenuItem(
                    value: LanguageMode.en,
                    child: Text(l.languageEnglish),
                  ),
                ],
                onChanged: controller.savingLanguage
                    ? null
                    : (mode) async {
                        if (mode == null) return;
                        try {
                          await controller.setLanguage(mode);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context).saveFailed,
                              ),
                            ),
                          );
                        }
                      },
              ),
              const SizedBox(height: 8),
              Text(l.languageHelp),
            ],
          ),
        ),
        InfoCard(
          icon: Icons.phone_android_outlined,
          title: l.localStorageTitle,
          body: l.localStorageBody,
        ),
        InfoCard(
          icon: Icons.image_outlined,
          title: l.backgroundTitle,
          body: l.backgroundLater,
        ),
        InfoCard(
          icon: Icons.calculate_outlined,
          title: l.calculationTitle,
          body: l.calculationPending,
        ),
        InfoCard(
          icon: Icons.palette_outlined,
          title: l.accentTitle,
          body: l.accentBody,
        ),
        FilledButton.icon(
          key: const ValueKey('edit_accent'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AccentColorEditor(controller: controller),
          ),
          icon: const Icon(Icons.tune),
          label: Text(l.accentAction),
        ),
      ],
    );
  }
}
