import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/features/navigation/home_screen.dart';
import 'package:inzirax/features/settings/settings_screen.dart';

class InziraxApp extends ConsumerWidget {
  const InziraxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        title: 'Inzirax',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff006d77)),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const HomeScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
        },
      );
}
