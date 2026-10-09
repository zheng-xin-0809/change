import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';

abstract interface class RecordStore {
  Future<void> initialize();
  Future<WeightEntry?> latestWeight();
  Future<WeightEntry?> weightFor(String date);
  Future<void> saveWeight(WeightEntry entry);
  Future<List<TrainingPlan>> plans();
  Future<List<TrainingPlan>> createPlan(String name);
  Future<List<TrainingPlan>> renamePlan(String id, String name);
  Future<List<TrainingPlan>> activatePlan(String id);
  Future<List<TrainingPlan>> deletePlan(String id);
  Future<void> close();
}

class LocalRecordStore implements RecordStore {
  LocalRecordStore({
    DatabaseFactory? factory,
    String? databasePath,
    Future<Directory> Function()? documentsDirectory,
  }) : _factory = factory ?? databaseFactory,
       _path = databasePath,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;
  final DatabaseFactory _factory;
  final Future<Directory> Function() _documentsDirectory;
  String? _path;
  Database? _db;
  Directory? mediaDirectory;

  static const schemaVersion = 1;
  static const schema = [
    '''CREATE TABLE exercises (
      id TEXT PRIMARY KEY, body_part_id TEXT NOT NULL,
      name_zh TEXT NOT NULL, name_en TEXT NOT NULL,
      instructions_zh TEXT NOT NULL, instructions_en TEXT NOT NULL
    )''',
    '''CREATE TABLE training_plans (
      id TEXT PRIMARY KEY, name TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 0 CHECK(active IN (0,1))
    )''',
    'CREATE UNIQUE INDEX one_active_plan ON training_plans(active) WHERE active = 1',
    '''CREATE TABLE plan_days (
      plan_id TEXT NOT NULL REFERENCES training_plans(id) ON DELETE CASCADE,
      weekday INTEGER NOT NULL CHECK(weekday BETWEEN 1 AND 7),
      kind TEXT NOT NULL CHECK(kind IN ('training','rest')),
      time_slot_id TEXT CHECK(time_slot_id IN ('after_breakfast','before_lunch','after_dinner','before_dinner')),
      body_part_ids TEXT NOT NULL DEFAULT '[]',
      exercise_ids TEXT NOT NULL DEFAULT '[]',
      CHECK((kind='rest' AND time_slot_id IS NULL) OR (kind='training' AND time_slot_id IS NOT NULL)),
      PRIMARY KEY(plan_id,weekday)
    )''',
    '''CREATE TABLE day_overrides (
      local_date TEXT PRIMARY KEY,
      kind TEXT NOT NULL CHECK(kind IN ('training','rest')),
      time_slot_id TEXT CHECK(time_slot_id IN ('after_breakfast','before_lunch','after_dinner','before_dinner')),
      body_part_ids TEXT NOT NULL DEFAULT '[]',
      exercise_ids TEXT NOT NULL DEFAULT '[]',
      CHECK((kind='rest' AND time_slot_id IS NULL) OR (kind='training' AND time_slot_id IS NOT NULL))
    )''',
    '''CREATE TABLE meal_entries (
      id TEXT PRIMARY KEY, local_date TEXT NOT NULL,
      meal_type_id TEXT NOT NULL CHECK(meal_type_id IN ('breakfast','pre_workout','post_workout','other')),
      food_name TEXT NOT NULL, carbs_g REAL NOT NULL CHECK(carbs_g >= 0),
      protein_g REAL NOT NULL CHECK(protein_g >= 0),
      fat_g REAL NOT NULL CHECK(fat_g >= 0), note TEXT NOT NULL DEFAULT ''
    )''',
    'CREATE INDEX meals_by_date ON meal_entries(local_date,meal_type_id)',
    '''CREATE TABLE weight_entries (
      local_date TEXT PRIMARY KEY, kilograms REAL NOT NULL CHECK(kilograms > 0)
    )''',
    '''CREATE TABLE check_ins (
      local_date TEXT PRIMARY KEY,
      kind TEXT NOT NULL CHECK(kind IN ('training','rest')),
      body_part_ids TEXT NOT NULL DEFAULT '[]', completed_at TEXT NOT NULL
    )''',
    '''CREATE TABLE photos (
      id TEXT PRIMARY KEY, meal_entry_id TEXT NOT NULL REFERENCES meal_entries(id) ON DELETE CASCADE,
      relative_path TEXT NOT NULL UNIQUE
    )''',
  ];

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    _path ??= p.join(await _factory.getDatabasesPath(), 'fit_notes.db');
    final db = await _factory.openDatabase(
      _path!,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          for (final statement in schema) {
            await db.execute(statement);
          }
        },
        // Explicitly reject unhandled upgrades; add migrations when schema changes.
        onUpgrade: (db, oldVersion, newVersion) =>
            throw StateError('Missing migration: $oldVersion -> $newVersion'),
      ),
    );
    try {
      mediaDirectory = await Directory(
        p.join((await _documentsDirectory()).path, 'media'),
      ).create(recursive: true);
      _db = db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('Record store is not initialized');
    return db;
  }

  WeightEntry _weight(Map<String, Object?> row) => WeightEntry(
    date: row['local_date'] as String,
    kilograms: (row['kilograms'] as num).toDouble(),
  );

  @override
  Future<WeightEntry?> latestWeight() async {
    final rows = await _database.query(
      'weight_entries',
      orderBy: 'local_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _weight(rows.single);
  }

  @override
  Future<WeightEntry?> weightFor(String date) async {
    final rows = await _database.query(
      'weight_entries',
      where: 'local_date = ?',
      whereArgs: [date],
    );
    return rows.isEmpty ? null : _weight(rows.single);
  }

  @override
  Future<void> saveWeight(WeightEntry entry) async {
    final parsed = DateTime.tryParse(entry.date);
    if (parsed == null ||
        localDateKey(parsed) != entry.date ||
        !entry.kilograms.isFinite ||
        entry.kilograms <= 0) {
      throw ArgumentError('Invalid weight entry');
    }
    await _database.insert('weight_entries', {
      'local_date': entry.date,
      'kilograms': entry.kilograms,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Scheduled collections will use JSON arrays of stable IDs, never labels.
  static String encodeIds(Iterable<String> ids) => jsonEncode(ids.toList());

  Future<List<TrainingPlan>> _plans(DatabaseExecutor db) async {
    final rows = await db.query('training_plans', orderBy: 'rowid ASC');
    return rows
        .map(
          (row) => TrainingPlan(
            id: row['id'] as String,
            name: row['name'] as String,
            active: row['active'] == 1,
          ),
        )
        .toList();
  }

  @override
  Future<List<TrainingPlan>> plans() => _plans(_database);

  Future<void> _requirePlan(DatabaseExecutor db, String id) async {
    if ((await db.query(
      'training_plans',
      where: 'id = ?',
      whereArgs: [id],
    )).isEmpty) {
      throw StateError('Plan no longer exists');
    }
  }

  @override
  Future<List<TrainingPlan>> createPlan(String name) async {
    final normalized = validatedPlanName(name);
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return _database.transaction((txn) async {
      final existing = await _plans(txn);
      await txn.insert('training_plans', {
        'id': id,
        'name': normalized,
        'active': existing.any((plan) => plan.active) ? 0 : 1,
      });
      return _plans(txn);
    });
  }

  @override
  Future<List<TrainingPlan>> renamePlan(String id, String name) async {
    final normalized = validatedPlanName(name);
    return _database.transaction((txn) async {
      await _requirePlan(txn, id);
      await txn.update(
        'training_plans',
        {'name': normalized},
        where: 'id = ?',
        whereArgs: [id],
      );
      return _plans(txn);
    });
  }

  @override
  Future<List<TrainingPlan>> activatePlan(String id) =>
      _database.transaction((txn) async {
        await _requirePlan(txn, id);
        await txn.update('training_plans', {'active': 0}, where: 'active = 1');
        await txn.update(
          'training_plans',
          {'active': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
        return _plans(txn);
      });

  @override
  Future<List<TrainingPlan>> deletePlan(String id) =>
      _database.transaction((txn) async {
        await _requirePlan(txn, id);
        await txn.delete('training_plans', where: 'id = ?', whereArgs: [id]);
        final remaining = await _plans(txn);
        if (remaining.isNotEmpty && !remaining.any((plan) => plan.active)) {
          await txn.update(
            'training_plans',
            {'active': 1},
            where: 'id = ?',
            whereArgs: [remaining.first.id],
          );
        }
        return _plans(txn);
      });

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
