import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_notes/domain/models.dart';
import 'package:fit_notes/domain/accent_color.dart';
import 'package:fit_notes/services/calculation_service.dart';
import 'package:fit_notes/ui/app.dart';
import 'package:fit_notes/ui/app_controller.dart';
import 'package:fit_notes/ui/app_theme.dart';

import 'test_support.dart';

class UnspecifiedInput implements CalculationInput {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Host visual QA only: this Windows font is never bundled in the APK.
    final systemFont = File(r'C:\Windows\Fonts\msyh.ttc');
    if (systemFont.existsSync()) {
      final bytes = await systemFont.readAsBytes();
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(bytes.buffer.asByteData()));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<AppController> start(
    WidgetTester tester, {
    MemoryLanguageStore? languages,
    MemoryAccentStore? accents,
    MemoryRecordStore? records,
    Locale system = const Locale('zh', 'CN'),
    double scale = 1,
    Size size = const Size(390, 844),
    GlobalKey? imageKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = [system];
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final controller = AppController(
      languageStore: languages ?? MemoryLanguageStore(),
      accentStore: accents ?? MemoryAccentStore(),
      records: records ?? MemoryRecordStore(),
    );
    await controller.initialize();
    await tester.pumpWidget(
      RepaintBoundary(
        key: imageKey,
        child: FitNotesApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> snapshot(WidgetTester tester, GlobalKey key, String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/qa/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'five pages navigate; Chinese follows Android; captures host UI',
    (tester) async {
      final key = GlobalKey();
      await start(tester, imageKey: key);
      expect(find.text('每天一小步'), findsOneWidget);
      await snapshot(tester, key, 'home_zh');
      await tester.tap(find.byKey(const ValueKey('nav_1')));
      await tester.pumpAndSettle();
      expect(find.text('还没有训练计划'), findsOneWidget);
      expect(find.text('早饭后'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav_2')));
      await tester.pumpAndSettle();
      expect(find.text('早饭'), findsOneWidget);
      expect(find.text('练前餐'), findsOneWidget);
      await snapshot(tester, key, 'diet_zh');
      await tester.tap(find.byKey(const ValueKey('nav_3')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await snapshot(tester, key, 'calendar_zh');
      await tester.tap(find.byKey(const ValueKey('nav_4')));
      await tester.pumpAndSettle();
      expect(find.text('跟随系统'), findsOneWidget);
      await snapshot(tester, key, 'settings_zh');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'language selection survives new controller; system choice follows changes',
    (tester) async {
      final languages = MemoryLanguageStore();
      final controller = await start(tester, languages: languages);
      await tester.tap(find.byKey(const ValueKey('nav_4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(languages.mode, LanguageMode.en);
      final restarted = AppController(
        languageStore: languages,
        accentStore: MemoryAccentStore(),
        records: MemoryRecordStore(),
      );
      await restarted.initialize();
      expect(restarted.locale, const Locale('en'));
      restarted.dispose();
      tester.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      await controller.setLanguage(LanguageMode.system);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, '设置'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = [const Locale('fr', 'FR')];
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    },
  );

  testWidgets('weight validation, successful save and home refresh', (
    tester,
  ) async {
    final records = MemoryRecordStore();
    await start(tester, records: records);
    await tester.tap(find.byKey(const ValueKey('home_weight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record_weight')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight_input')), '-1');
    await tester.tap(find.byKey(const ValueKey('save_weight')));
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的有效体重'), findsOneWidget);
    expect(records.weights, isEmpty);
    await tester.enterText(find.byKey(const ValueKey('weight_input')), '65,5');
    await tester.tap(find.byKey(const ValueKey('save_weight')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(records.weights.values.single.kilograms, 65.5);
    await tester.tap(find.byKey(const ValueKey('nav_0')));
    await tester.pumpAndSettle();
    expect(find.text('65.5 千克'), findsOneWidget);
  });

  Future<void> createPlan(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const ValueKey('create_plan')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('plan_name')), name);
    await tester.tap(find.byKey(const ValueKey('submit_plan')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'plans create, rename, switch, cancel deletion and delete to empty',
    (tester) async {
      final records = MemoryRecordStore();
      final key = GlobalKey();
      final controller = await start(tester, records: records, imageKey: key);
      await tester.tap(find.byKey(const ValueKey('nav_1')));
      await tester.pumpAndSettle();
      await createPlan(tester, '  力量训练  ');
      final firstId = controller.activePlan!.id;
      expect(find.text('力量训练'), findsOneWidget);
      await createPlan(tester, '周末 Plan');
      final secondId = controller.plans.last.id;
      expect(controller.activePlan!.id, firstId);
      await tester.tap(find.byKey(ValueKey('rename_$secondId')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('plan_name')), '周末全身');
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('activate_$secondId')));
      await tester.pumpAndSettle();
      expect(controller.activePlan!.name, '周末全身');
      await snapshot(tester, key, 'plans_zh');
      final restarted = AppController(
        languageStore: MemoryLanguageStore(),
        accentStore: MemoryAccentStore(),
        records: records,
      );
      await restarted.initialize();
      expect(restarted.activePlan!.id, secondId);
      restarted.dispose();
      await controller.setLanguage(LanguageMode.en);
      await tester.pumpAndSettle();
      expect(find.text('周末全身'), findsOneWidget);
      expect(find.text('Current plan'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('delete_$secondId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cancel_plan')));
      await tester.pumpAndSettle();
      expect(controller.plans, hasLength(2));
      await tester.tap(find.byKey(ValueKey('delete_$secondId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      expect(controller.activePlan!.id, firstId);
      await tester.tap(find.byKey(ValueKey('delete_$firstId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      expect(find.text('No training plans yet'), findsOneWidget);
      expect(controller.activePlan, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid plan names, storage failures and retry preserve user input',
    (tester) async {
      final records = MemoryRecordStore();
      final controller = await start(tester, records: records);
      await tester.tap(find.byKey(const ValueKey('nav_1')));
      await tester.pumpAndSettle();
      await createPlan(tester, '   ');
      expect(find.text('请输入 1 至 60 个字符的名称。'), findsOneWidget);
      expect(controller.plans, isEmpty);
      records.failPlans = true;
      await tester.enterText(find.byKey(const ValueKey('plan_name')), '保留输入');
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      expect(find.text('计划修改失败，请重试。原有计划保留。'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('plan_name')))
            .controller!
            .text,
        '保留输入',
      );
      expect(controller.savingPlan, isFalse);
      records.failPlans = false;
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      final id = controller.activePlan!.id;
      records.failPlans = true;
      await tester.tap(find.byKey(ValueKey('delete_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit_plan')));
      await tester.pumpAndSettle();
      expect(controller.activePlan!.id, id);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cancel_plan')));
      await tester.pumpAndSettle();
      await expectLater(controller.renamePlan(id, '失败名称'), throwsStateError);
      expect(controller.activePlan!.name, '保留输入');
    },
  );

  testWidgets(
    'English plan dialogs and long names fit narrow large-text screens',
    (tester) async {
      final key = GlobalKey();
      final controller = await start(
        tester,
        system: const Locale('en'),
        scale: 1.5,
        size: const Size(360, 800),
        imageKey: key,
      );
      await tester.tap(find.byKey(const ValueKey('nav_1')));
      await tester.pumpAndSettle();
      await createPlan(tester, List.filled(60, 'W').join());
      expect(controller.plans, hasLength(1));
      await snapshot(tester, key, 'plans_en_large');
      await tester.tap(
        find.byKey(ValueKey('rename_${controller.plans.single.id}')),
      );
      await tester.pumpAndSettle();
      await snapshot(tester, key, 'plan_dialog_en_large');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('accent hex edits preview, save and persist locally', (
    tester,
  ) async {
    final accents = MemoryAccentStore();
    final controller = await start(tester, accents: accents);
    await tester.tap(find.byKey(const ValueKey('nav_4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('edit_accent')),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('强调色'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit_accent')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('accent_hex')), '#FF0000');
    await tester.pumpAndSettle();
    expect(find.text('红色: 255'), findsOneWidget);
    expect(find.text('绿色: 0'), findsOneWidget);
    expect(find.text('蓝色: 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save_accent')));
    await tester.pumpAndSettle();
    expect(controller.accentColor.hex, '#FF0000');
    expect(accents.color.hex, '#FF0000');

    final restarted = AppController(
      languageStore: MemoryLanguageStore(),
      accentStore: accents,
      records: MemoryRecordStore(),
    );
    await restarted.initialize();
    expect(restarted.accentColor.hex, '#FF0000');
    restarted.dispose();

    await tester.tap(find.byKey(const ValueKey('edit_accent')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('accent_hex')), 'red');
    await tester.pumpAndSettle();
    expect(find.text('请输入六位十六进制颜色，例如 #166A58。'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('save failures retain the input and prior language', (
    tester,
  ) async {
    final records = MemoryRecordStore()..failSave = true;
    final languages = MemoryLanguageStore()..failWrite = true;
    final controller = await start(
      tester,
      records: records,
      languages: languages,
    );
    await tester.tap(find.byKey(const ValueKey('nav_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record_weight')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight_input')), '66');
    await tester.tap(find.byKey(const ValueKey('save_weight')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('保存失败，请重试。原有记录保留。'), findsOneWidget);
    expect(records.weights, isEmpty);
    await expectLater(
      controller.setLanguage(LanguageMode.en),
      throwsStateError,
    );
    expect(controller.languageMode, LanguageMode.system);
    expect(controller.savingLanguage, isFalse);
  });

  testWidgets(
    'English fallback and large text remain usable on narrow screens',
    (tester) async {
      final key = GlobalKey();
      await start(
        tester,
        system: const Locale('de'),
        scale: 1.5,
        size: const Size(360, 800),
        imageKey: key,
      );
      expect(find.text('One day at a time'), findsOneWidget);
      for (var index = 0; index < 5; index++) {
        await tester.tap(find.byKey(ValueKey('nav_$index')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'English page $index at 150% text',
        );
      }
      await snapshot(tester, key, 'settings_en_large');
    },
  );

  testWidgets('startup storage failure is localized and retry recovers', (
    tester,
  ) async {
    final records = MemoryRecordStore()..failInitialize = true;
    final controller = await start(tester, records: records);
    expect(find.text('无法打开本地存储'), findsOneWidget);
    records.failInitialize = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(controller.ready, isTrue);
    expect(find.text('每天一小步'), findsOneWidget);
  });

  test('calculation stays unavailable and never invents targets', () async {
    const service = PendingCalculationService();
    expect(service.isAvailable, isFalse);
    await expectLater(
      service.calculate(UnspecifiedInput(), TrainingTime.beforeLunch),
      throwsA(isA<CalculationNotConfigured>()),
    );
  });

  test('accent contrast helper chooses readable foregrounds', () {
    expect(textOnAccent(const Color(0xFFFFFFFF)), Colors.black);
    expect(textOnAccent(const Color(0xFF000000)), Colors.white);
    expect(contrastRatio(Colors.black, Colors.white), greaterThanOrEqualTo(21));
    expect(AccentColor.parse('#12aBcD')!.hex, '#12ABCD');
    expect(AccentColor.parse('#12ABC'), isNull);
  });
}
