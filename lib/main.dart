import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_service.dart';
import 'core/storage/local_cache_service.dart';
import 'core/utils/formatters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFormatters.initialize();

  // Notifikasi: kanal lokal + Firebase Cloud Messaging (bila dikonfigurasi).
  await NotificationService.instance.init();
  await PushService.instance.initialize();
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
