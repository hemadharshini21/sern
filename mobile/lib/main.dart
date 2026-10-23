import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web, skip native push notification binding to prevent WipError debugger desync
  if (!kIsWeb) {
    try {
      await NotificationService().init();
    } catch (_) {}
  }
  runApp(const SernApp());
}

class SernApp extends StatelessWidget {
  const SernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SERN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
