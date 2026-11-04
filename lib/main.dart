import 'package:flutter/material.dart';

import 'oee_form.dart';

void main() {
  runApp(const OeeApp());
}

class OeeApp extends StatelessWidget {
  const OeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculador OEE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E56)),
        inputDecorationTheme: const InputDecorationTheme(
          constraints: BoxConstraints(minHeight: 48),
        ),
      ),
      home: const OeeForm(),
    );
  }
}
