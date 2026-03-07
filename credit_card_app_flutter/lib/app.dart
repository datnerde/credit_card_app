import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/theme.dart';

class CreditCardApp extends StatelessWidget {
  const CreditCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'SmartCard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: settings.hasCompletedOnboarding
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
