import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_foundation_page.dart';
import 'oee_form.dart';
import 'plant_map_page.dart';
import 'plant_store.dart';
import 'workspace_idb.dart';
import 'workspace_idb_factory.dart';
import 'workspace_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PreferencesPlantStore(
    read: (key) async => prefs.getString(key),
    write: (key, value) async {
      await prefs.setString(key, value);
    },
  );
  final workspace = WorkspaceRepository(
    database: IdbWorkspaceDatabase(createWorkspaceIdbFactory()),
    readLegacy: () async => prefs.getString(plantStorageKey),
  );
  await workspace.open();
  runApp(OeeApp(store: store, workspace: workspace));
}

class OeeApp extends StatefulWidget {
  const OeeApp({super.key, required this.store, this.workspace});

  final PlantStore store;
  final WorkspaceRepository? workspace;

  @override
  State<OeeApp> createState() => _OeeAppState();
}

enum _Screen { oee, map, data }

class _OeeAppState extends State<OeeApp> {
  _Screen _screen = _Screen.oee;

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final title = switch (_screen) {
      _Screen.oee => 'Calculador OEE',
      _Screen.map => 'Mapa ISA-95',
      _Screen.data => 'Dades locals',
    };
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E56)),
        inputDecorationTheme: const InputDecorationTheme(
          constraints: BoxConstraints(minHeight: 48),
        ),
      ),
      home: switch (_screen) {
        _Screen.map => PlantMapPage(
          store: widget.store,
          onOpenOee: () => setState(() => _screen = _Screen.oee),
          onOpenData: workspace == null
              ? null
              : () => setState(() => _screen = _Screen.data),
        ),
        _Screen.data when workspace != null => DataFoundationPage(
          repository: workspace,
          onOpenOee: () => setState(() => _screen = _Screen.oee),
          onOpenMap: () => setState(() => _screen = _Screen.map),
        ),
        _ => OeeForm(
          onOpenMap: () => setState(() => _screen = _Screen.map),
          onOpenData: workspace == null
              ? null
              : () => setState(() => _screen = _Screen.data),
        ),
      },
    );
  }
}
