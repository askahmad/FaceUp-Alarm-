// lib/main.dart
// FaceUp Alarm - App Entry Point
// Ye file sab se pehle chalti hai

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter initialize karo
  WidgetsFlutterBinding.ensureInitialized();

  // Sirf portrait mode allow karo (alarm app ke liye better hai)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparent karo aur dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Storage service initialize karo
  // Ye pehle karna zaroori hai taake alarms read ho sakein
  await StorageService().init();

  // App chalaao
  runApp(const FaceUpAlarmApp());
}

class FaceUpAlarmApp extends StatelessWidget {
  const FaceUpAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App ka naam
      title: 'FaceUp Alarm - چہرہ الارم',

      // Debug badge hata do
      debugShowCheckedModeBanner: false,

      // App theme
      theme: AppTheme.lightTheme,

      // Pehla screen - Home
      home: const HomeScreen(),

      // Urdu text ke liye RTL support
      // Note: We use mixed RTL/LTR, so we keep it LTR as base
      // Individual Urdu texts will use TextDirection.rtl where needed
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
