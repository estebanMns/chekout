import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';

void main() => runApp(const ProStoreApp());

class ProStoreApp extends StatelessWidget {
  const ProStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProStore E-commerce',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 21, 127, 25),
          primary: const Color.fromARGB(255, 10, 164, 31),
          secondary: const Color.fromARGB(255, 4, 255, 0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const MainNavigation(),
    );
  }
}