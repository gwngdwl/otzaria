import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/splash_screen.dart';
import 'package:otzaria/theme/theme_exports.dart';

void main() {
  testWidgets('SplashApp uses the default light app theme', (tester) async {
    await tester.pumpWidget(const SplashApp());

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    final expectedColorScheme = AppThemeData.createColorScheme(
      AppSeedColors.defaultLight,
      Brightness.light,
    );

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, expectedColorScheme.primary);
    expect(theme.colorScheme.secondary, expectedColorScheme.secondary);
    expect(theme.colorScheme.surface, expectedColorScheme.surface);
  });
}
