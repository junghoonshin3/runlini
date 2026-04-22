import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/dashboard/ui/runlini_home_screen.dart';

class RunliniApp extends StatelessWidget {
  const RunliniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runlini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const RunliniHomeScreen(),
    );
  }
}
