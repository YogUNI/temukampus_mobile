import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/storage/local_cache_service.dart';
import 'core/utils/formatters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFormatters.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const TemuKampusApp(),
    ),
  );
}
