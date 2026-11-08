import 'package:flutter/material.dart';

import 'workspace_model.dart';

const Color anthracite = Color(0xFF1E242B);
const Color steel = Color(0xFF5C6B7A);
const Color steelLine = Color(0xFFD5DCE3);
const Color canvas = Color(0xFFF4F6F8);
const Color panel = Color(0xFFFFFFFF);
const Color ink = Color(0xFF1C2128);
const Color itBand = Color(0xFFE4EEF5);
const Color l3Band = Color(0xFFF8F1E3);
const Color otBand = Color(0xFFE7F0EA);
const Color undefinedBand = Color(0xFFEEF0F2);
const Color citedBand = Color(0xFFF7F7F8);
const Color accent = Color(0xFF3D6F8F);

const ButtonStyle workspaceControlStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(48, 48)),
  visualDensity: VisualDensity.standard,
  tapTargetSize: MaterialTapTargetSize.padded,
);

ThemeData workspaceTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    colorScheme: const ColorScheme.light(
      primary: accent,
      onPrimary: panel,
      secondary: steel,
      surface: panel,
      onSurface: ink,
      error: Color(0xFF8C3A3A),
    ),
    dividerColor: steelLine,
  );
  return base.copyWith(
    focusColor: anthracite,
    hoverColor: const Color(0x143D6F8F),
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      constraints: BoxConstraints(minHeight: 48),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: anthracite, width: 2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: workspaceControlStyle.copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: anthracite, width: 2);
          }
          return const BorderSide(color: steel);
        }),
        foregroundColor: const WidgetStatePropertyAll(ink),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: workspaceControlStyle.copyWith(
        foregroundColor: const WidgetStatePropertyAll(ink),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: anthracite, width: 2);
          }
          return BorderSide.none;
        }),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: workspaceControlStyle,
    ),
  );
}

String iconKeyLabel(IconKey key) {
  switch (key) {
    case IconKey.organization:
      return 'Organització';
    case IconKey.plant:
      return 'Planta';
    case IconKey.area:
      return 'Àrea';
    case IconKey.line:
      return 'Línia';
    case IconKey.machine:
      return 'Màquina';
    case IconKey.erp:
      return 'ERP';
    case IconKey.mes:
      return 'MES';
    case IconKey.scada:
      return 'SCADA';
    case IconKey.plc:
      return 'PLC';
    case IconKey.genericSystem:
      return 'Sistema';
  }
}

IconData iconFor(IconKey key) {
  switch (key) {
    case IconKey.organization:
      return Icons.apartment;
    case IconKey.plant:
      return Icons.factory_outlined;
    case IconKey.area:
      return Icons.grid_view;
    case IconKey.line:
      return Icons.linear_scale;
    case IconKey.machine:
      return Icons.precision_manufacturing_outlined;
    case IconKey.erp:
      return Icons.account_balance_outlined;
    case IconKey.mes:
      return Icons.factory;
    case IconKey.scada:
      return Icons.desktop_windows_outlined;
    case IconKey.plc:
      return Icons.memory;
    case IconKey.genericSystem:
      return Icons.device_hub_outlined;
  }
}

String flowStatusLabel(FlowStatus status) {
  switch (status) {
    case FlowStatus.suggested:
      return 'Suggerit';
    case FlowStatus.confirmed:
      return 'Confirmat';
  }
}

String functionChip(IsaFunction function) {
  final code = switch (function) {
    IsaFunction.l0 => 'L0',
    IsaFunction.l1 => 'L1',
    IsaFunction.l2 => 'L2',
    IsaFunction.l3 => 'L3',
    IsaFunction.l4 => 'L4',
  };
  return '$code · ${isaFunctionLabel(function)}';
}
