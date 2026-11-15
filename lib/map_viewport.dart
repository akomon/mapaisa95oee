import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Visor del mapa.
///
/// La roda del ratolí desplaça el contingut; no fa zoom. El zoom és dels
/// botons, del teclat i del gest de pessigar. Arrossegar també desplaça, com
/// abans.
class MapViewport extends StatefulWidget {
  const MapViewport({
    super.key,
    required this.controller,
    required this.contentSize,
    required this.onScroll,
    required this.child,
    this.minScale = 0.35,
    this.maxScale = 2.5,
  });

  final TransformationController controller;
  final Size contentSize;
  final ValueChanged<PointerScrollEvent> onScroll;
  final Widget child;
  final double minScale;
  final double maxScale;

  @override
  State<MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<MapViewport> {
  /// Marge mínim del contingut que sempre queda visible.
  static const double _keepVisible = 80;

  late Matrix4 _startMatrix;
  late double _startScale;
  late Offset _startFocalScene;

  void _onScaleStart(ScaleStartDetails details) {
    _startMatrix = widget.controller.value.clone();
    _startScale = _startMatrix.getMaxScaleOnAxis();
    _startFocalScene = _toScene(details.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final viewport = context.size;
    if (viewport == null) {
      return;
    }
    final scale = (_startScale * details.scale)
        .clamp(widget.minScale, widget.maxScale)
        .toDouble();
    final focal = details.localFocalPoint;
    final scene = _startFocalScene;
    final width = widget.contentSize.width * scale;
    final height = widget.contentSize.height * scale;
    final dx = (focal.dx - scene.dx * scale).clamp(
      _keepVisible - width,
      viewport.width - _keepVisible,
    );
    final dy = (focal.dy - scene.dy * scale).clamp(
      _keepVisible - height,
      viewport.height - _keepVisible,
    );
    widget.controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Offset _toScene(Offset point) {
    final matrix = widget.controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    return Offset(
      (point.dx - translation.x) / scale,
      (point.dy - translation.y) / scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          widget.onScroll(event);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) => Transform(
                transform: widget.controller.value,
                alignment: Alignment.topLeft,
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
