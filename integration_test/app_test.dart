import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_notes/data/language_store.dart';
import 'package:fit_notes/data/local_record_store.dart';
import 'package:fit_notes/domain/models.dart';
import 'package:fit_notes/ui/app.dart';
import 'package:fit_notes/ui/app_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android native preferences and SQLite persist across app recreation',
    (tester) async {
      final documents = await getApplicationDocumentsDirectory();
      final isolated = await Directory(
        p.join(documents.path, 'integration_test_data'),
      ).create(recursive: true);
      const preferenceKey = 'integration_test.locale_mode';
      final preferences = SharedPreferencesAsync();
      LocalRecordStore newStore() => LocalRecordStore(
        databasePath: p.join(isolated.path, 'test.db'),
        documentsDirectory: () async => isolated,
      );
      var store = newStore();
      var controller = AppController(
        languageStore: LocalLanguageStore(key: preferenceKey),
        records: store,
      );
      try {
        await preferences.remove(preferenceKey);
        await controller.initialize();
        await tester.pumpWidget(FitNotesApp(controller: controller));
        await tester.pumpAndSettle();
        await controller.setLanguage(LanguageMode.en);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav_2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('record_weight')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('weight_input')),
          '65.5',
        );
        await tester.tap(find.byKey(const ValueKey('save_weight')));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        controller.dispose();
        await store.close();
        store = newStore();
        controller = AppController(
          languageStore: LocalLanguageStore(key: preferenceKey),
          records: store,
        );
        await controller.initialize();
        expect(controller.locale, const Locale('en'));
        expect(
          (await store.weightFor(localDateKey(DateTime.now())))!.kilograms,
          65.5,
        );
        expect(store.mediaDirectory!.existsSync(), isTrue);
        await tester.pumpWidget(FitNotesApp(controller: controller));
        await tester.pumpAndSettle();
        expect(find.text('One day at a time'), findsOneWidget);
        expect(find.text('65.5 kg'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await store.close();
        await preferences.remove(preferenceKey);
        await isolated.delete(recursive: true);
      }
    },
  );
}
