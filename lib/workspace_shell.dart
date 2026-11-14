import 'package:flutter/material.dart';

import 'workspace_theme.dart';

const Key workspaceRailKey = Key('workspaceRail');
const Key workspaceRailCalculatorKey = Key('workspaceRailCalculator');
const Key workspaceRailEngineKey = Key('workspaceRailEngine');
const Key workspaceRailMapKey = Key('workspaceRailMap');
const Key workspaceRailDataKey = Key('workspaceRailData');
const Key workspaceBottomBarKey = Key('workspaceBottomBar');

const double workspaceRailWidth = 76;
const double workspaceRailWidthCompact = 64;

enum WorkspaceSection { calculator, engine, map, data }

/// Closca comuna de l'aplicació: barra lateral antracita, capçalera de panell
/// i barra inferior amb l'estètica del mapa.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    super.key,
    required this.current,
    required this.header,
    required this.child,
    this.bottom,
    this.onOpenCalculator,
    this.onOpenEngine,
    this.onOpenMap,
    this.onOpenData,
  });

  final WorkspaceSection current;
  final Widget header;
  final Widget child;
  final Widget? bottom;
  final VoidCallback? onOpenCalculator;
  final VoidCallback? onOpenEngine;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenData;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: workspaceTheme(),
      child: Scaffold(
        backgroundColor: canvas,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspaceRail(
              current: current,
              onOpenCalculator: onOpenCalculator,
              onOpenEngine: onOpenEngine,
              onOpenMap: onOpenMap,
              onOpenData: onOpenData,
            ),
            Expanded(
              child: SafeArea(
                left: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(child: child),
                    ?bottom,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceRail extends StatelessWidget {
  const WorkspaceRail({
    super.key,
    required this.current,
    this.onOpenCalculator,
    this.onOpenEngine,
    this.onOpenMap,
    this.onOpenData,
  });

  final WorkspaceSection current;
  final VoidCallback? onOpenCalculator;
  final VoidCallback? onOpenEngine;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenData;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      key: workspaceRailKey,
      width: compact ? workspaceRailWidthCompact : workspaceRailWidth,
      color: anthracite,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          _railButton(
            key: workspaceRailCalculatorKey,
            icon: Icons.calculate_outlined,
            label: 'Calculador',
            section: WorkspaceSection.calculator,
            compact: compact,
            onPressed: onOpenCalculator,
          ),
          _railButton(
            key: workspaceRailEngineKey,
            icon: Icons.speed,
            label: 'Càlcul',
            section: WorkspaceSection.engine,
            compact: compact,
            onPressed: onOpenEngine,
          ),
          _railButton(
            key: workspaceRailMapKey,
            icon: Icons.account_tree,
            label: 'Mapa',
            section: WorkspaceSection.map,
            compact: compact,
            onPressed: onOpenMap,
          ),
          _railButton(
            key: workspaceRailDataKey,
            icon: Icons.folder_outlined,
            label: 'Dades',
            section: WorkspaceSection.data,
            compact: compact,
            onPressed: onOpenData,
          ),
        ],
      ),
    );
  }

  Widget _railButton({
    required Key key,
    required IconData icon,
    required String label,
    required WorkspaceSection section,
    required bool compact,
    required VoidCallback? onPressed,
  }) {
    final active = section == current;
    final enabled = active || onPressed != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          key: key,
          style: TextButton.styleFrom(
            foregroundColor: enabled ? panel : const Color(0x80FFFFFF),
            backgroundColor: active ? railActive : Colors.transparent,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: active ? () {} : onPressed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 10 : 11, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capçalera de panell clar, com la de l'espai de treball.
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: panel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    ),
                ],
              ),
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

/// Barra inferior amb el contenidor i l'espaiat de la barra del mapa.
class WorkspaceBottomBar extends StatelessWidget {
  const WorkspaceBottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: workspaceBottomBarKey,
      color: bottomBarSurface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(right: 8), child: child),
          ],
        ),
      ),
    );
  }
}

/// Botó de barra o de capçalera amb l'estil dels controls del mapa.
Widget workspaceBarButton({
  Key? key,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
}) {
  final style = workspaceControlStyle;
  if (icon == null) {
    return OutlinedButton(
      key: key,
      style: style,
      onPressed: onPressed,
      child: Text(label),
    );
  }
  return OutlinedButton.icon(
    key: key,
    style: style,
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );
}
