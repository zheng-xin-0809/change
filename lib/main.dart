import 'dart:async';

import 'package:flutter/material.dart';

import 'data/language_store.dart';
import 'data/accent_store.dart';
import 'data/local_record_store.dart';
import 'ui/app.dart';
import 'ui/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    languageStore: LocalLanguageStore(),
    accentStore: LocalAccentStore(),
    records: LocalRecordStore(),
  );
  runApp(FitNotesApp(controller: controller));
  unawaited(controller.initialize());
}
