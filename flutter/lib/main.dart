import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/constants.dart';
import 'package:dermascan/app/navigation_routes.dart';
import 'package:dermascan/app/translation/messages.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:dermascan/core/services/local_asset_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseURL, anonKey: anonKey);

  await Get.putAsync(() async => AuthService());
  await Get.putAsync(() async => DBService());

  await LocalAssetServer.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: NavigationRoutes.getRoutes,
      translations: Messages(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
    );
  }
}
