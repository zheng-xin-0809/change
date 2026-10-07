import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_notes/domain/models.dart';
import 'package:fit_notes/services/calculation_service.dart';
import 'package:fit_notes/ui/app.dart';
import 'package:fit_notes/ui/app_controller.dart';

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
}
