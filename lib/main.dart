import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_provider.dart';
import 'state/time_provider.dart';
import 'theme/pixel.dart';

void main() {
  runApp(const CicloTesteApp());
}

class CicloTesteApp extends StatelessWidget {
  const CicloTesteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => TimeProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Ciclo de Teste',
        debugShowCheckedModeBanner: false,
        theme: Px.theme(),
        home: const HomeScreen(),
      ),
    );
  }
}
