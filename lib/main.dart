import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oee_form.dart';
import 'plant_map_page.dart';
import 'plant_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PreferencesPlantStore(
    read: (key) async => prefs.getString(key),
    write: (key, value) async {
      await prefs.setString(key, value);
    },
  );
  runApp(OeeApp(store: store));
}

class OeeApp extends StatefulWidget {
  const OeeApp({super.key, required this.store});

  final PlantStore store;

  @override
  State<OeeApp> createState() => _OeeAppState();
}

class _OeeAppState extends State<OeeApp> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _showMap ? 'Mapa ISA-95' : 'Calculador OEE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E56)),
        inputDecorationTheme: const InputDecorationTheme(
          constraints: BoxConstraints(minHeight: 48),
        ),
      ),
      home: _showMap
          ? PlantMapPage(
              store: widget.store,
              onOpenOee: () => setState(() => _showMap = false),
            )
          : OeeForm(
              onOpenMap: () => setState(() => _showMap = true),
            ),
    );
  }
}
