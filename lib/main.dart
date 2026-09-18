import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_provider.dart';

void main() {
  runApp(const CicloTesteApp());
}

class CicloTesteApp extends StatelessWidget {
  const CicloTesteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B8CFF),
      brightness: Brightness.dark,
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Cronômetro de Ciclo de Teste',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFF0B0F1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111729),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF161D2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
