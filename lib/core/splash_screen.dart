import 'package:flutter/material.dart';
import 'package:otzaria/theme/theme_exports.dart';

/// מסך פתיחה מוצג בזמן האתחול לפני שה-App נטען
class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppThemeData.light(
        AppThemeData.createColorScheme(
          AppSeedColors.defaultLight,
          Brightness.light,
        ),
        compactMenuMode: false,
      ),
      darkTheme: AppThemeData.dark(
        AppSeedColors.defaultDark,
        compactMenuMode: false,
      ),
      home: Scaffold(
        body: Center(
          child: Image(
            image: AssetImage('assets/icon/iconnew.png'),
            width: 128,
            height: 128,
          ),
        ),
      ),
    );
  }
}
