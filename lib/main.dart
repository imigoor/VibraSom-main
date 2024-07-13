import 'package:flutter/material.dart';
import 'package:VibraSound/core/app_export.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),  // ALTERAÇÃO
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vibrasom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splashscreen': (context) => const SplashScreen(),
        '/mainscreen': (context) => const MainScreen(),
      },
    );
  }
}