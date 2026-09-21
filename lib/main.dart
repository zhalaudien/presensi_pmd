import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/database_helper.dart';
import 'core/storage/preferences_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await PreferencesHelper.init();

  // Initialize SQLite local database
  await DatabaseHelper.database;

  runApp(
    ProviderScope(
      overrides: [
        preferencesHelperProvider.overrideWithValue(prefs),
      ],
      child: const PresensiApp(),
    ),
  );
}
