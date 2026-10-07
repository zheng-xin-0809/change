import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fit_notes/data/local_record_store.dart';
import 'package:fit_notes/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late Directory temporary;
  late String path;
  late LocalRecordStore store;
  LocalRecordStore createStore() => LocalRecordStore(
    factory: databaseFactoryFfi,
    databasePath: path,
    documentsDirectory: () async => temporary,
  );

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('fit_notes_test_');
    path = p.join(temporary.path, 'records.db');
    store = createStore();
    await store.initialize();
  });
  tearDown(() async {
    await store.close();
    await temporary.delete(recursive: true);
  });

  test(
    'weight survives reopening; same date updates while other days remain',
    () async {
      expect(await store.latestWeight(), isNull);
      await store.saveWeight(
        const WeightEntry(date: '2026-10-06', kilograms: 67),
      );
      await store.saveWeight(
        const WeightEntry(date: '2026-10-07', kilograms: 66.5),
      );
      await store.saveWeight(
        const WeightEntry(date: '2026-10-07', kilograms: 66.2),
      );
      await store.close();
      store = createStore();
      await store.initialize();
      expect((await store.latestWeight())!.kilograms, 66.2);
      expect((await store.weightFor('2026-10-06'))!.kilograms, 67);
      expect(await store.weightFor('2026-10-08'), isNull);
      expect(store.mediaDirectory!.existsSync(), isTrue);
      final db = await databaseFactoryFfi.openDatabase(path);
      expect(await db.getVersion(), LocalRecordStore.schemaVersion);
      expect(
        (await db.rawQuery('SELECT count(*) FROM weight_entries'))
            .single
            .values
            .single,
        2,
      );
    },
  );

  test(
    'invalid values are rejected without overwriting existing data',
    () async {
      await store.saveWeight(
        const WeightEntry(date: '2026-10-07', kilograms: 65),
      );
      for (final value in [0.0, -1.0, double.nan, double.infinity]) {
        await expectLater(
          store.saveWeight(WeightEntry(date: '2026-10-07', kilograms: value)),
          throwsArgumentError,
        );
      }
      await expectLater(
        store.saveWeight(const WeightEntry(date: '2026-02-30', kilograms: 65)),
        throwsArgumentError,
      );
      expect((await store.latestWeight())!.kilograms, 65);
    },
  );

  test(
    'schema enforces parent references, single active plan and fixed IDs',
    () async {
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.insert('training_plans', {
        'id': 'a',
        'name': '我的 Plan',
        'active': 1,
      });
      await expectLater(
        db.insert('training_plans', {
          'id': 'b',
          'name': 'Another',
          'active': 1,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('photos', {
          'id': 'p',
          'meal_entry_id': 'missing',
          'relative_path': 'media/p.jpg',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await db.insert('plan_days', {
        'plan_id': 'a',
        'weekday': 1,
        'kind': 'rest',
      });
      await expectLater(
        db.insert('plan_days', {'plan_id': 'a', 'weekday': 8, 'kind': 'rest'}),
        throwsA(isA<DatabaseException>()),
      );
      await db.insert('meal_entries', {
        'id': 'meal',
        'local_date': '2026-10-07',
        'meal_type_id': MealType.breakfast.id,
        'food_name': '鸡蛋 egg',
        'carbs_g': 0,
        'protein_g': 6,
        'fat_g': 5,
        'note': '自填 note',
      });
      final meal = (await db.query('meal_entries')).single;
      expect(meal['food_name'], '鸡蛋 egg');
      expect(meal['note'], '自填 note');
      await db.delete('training_plans', where: 'id = ?', whereArgs: ['a']);
      expect(await db.query('plan_days'), isEmpty);
    },
  );
}
