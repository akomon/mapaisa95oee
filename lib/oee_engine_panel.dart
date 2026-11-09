import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'oee_engine.dart';
import 'workspace_model.dart';
import 'workspace_theme.dart';

const Key enginePlannedKey = Key('enginePlannedMinutes');
const Key engineDowntimeKey = Key('engineDowntimeMinutes');
const Key engineSpeedKey = Key('engineSpeed');
const Key engineTotalKey = Key('engineTotalUnits');
const Key engineGoodKey = Key('engineGoodUnits');
const Key engineUnitSecondsKey = Key('engineUnitSeconds');
const Key engineUnitRateKey = Key('engineUnitRate');
const Key enginePieKey = Key('enginePie');
const Key engineResultKey = Key('engineResult');

class OeeEnginePage extends StatelessWidget {
  const OeeEnginePage({
    super.key,
    this.onOpenCalculator,
    this.onOpenMap,
    this.onOpenData,
    this.lineName,
  });

  final VoidCallback? onOpenCalculator;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenData;
  final String? lineName;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: workspaceTheme(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: anthracite,
          foregroundColor: panel,
          title: const Text('Càlcul OEE'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onOpenCalculator != null) ...[
                      OutlinedButton(
                        style: workspaceControlStyle,
                        onPressed: onOpenCalculator,
                        child: const Text('Calculador US-1'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (onOpenMap != null) ...[
                      OutlinedButton(
                        style: workspaceControlStyle,
                        onPressed: onOpenMap,
                        child: const Text('Mapa ISA-95'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (onOpenData != null) ...[
                      OutlinedButton(
                        style: workspaceControlStyle,
                        onPressed: onOpenData,
                        child: const Text('Dades locals'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OeeEnginePanel(lineName: lineName),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OeeEnginePanel extends StatefulWidget {
  const OeeEnginePanel({super.key, this.lineName});

  final String? lineName;

  @override
  State<OeeEnginePanel> createState() => _OeeEnginePanelState();
}

class _OeeEnginePanelState extends State<OeeEnginePanel> {
  final TextEditingController _planned = TextEditingController();
  final TextEditingController _downtime = TextEditingController();
  final TextEditingController _speed = TextEditingController();
  final TextEditingController _total = TextEditingController();
  final TextEditingController _good = TextEditingController();
  final FocusNode _plannedFocus = FocusNode();
  final FocusNode _unitRateFocus = FocusNode();

  SpeedUnit _unit = SpeedUnit.secondsPerUnit;
  double? _canonical;

  @override
  void dispose() {
    _planned.dispose();
    _downtime.dispose();
    _speed.dispose();
    _total.dispose();
    _good.dispose();
    _plannedFocus.dispose();
    _unitRateFocus.dispose();
    super.dispose();
  }

  void _changed(String _) {
    setState(() {});
  }

  void _onSpeed(String raw) {
    setState(() {
      final parsed = parseOeeEngineDecimal(raw);
      final value = parsed.value;
      if (value != null && value > 0) {
        _canonical = canonicalCycleSeconds(value, _unit);
      } else {
        _canonical = null;
      }
    });
  }

  void _setUnit(SpeedUnit unit) {
    if (unit == _unit) {
      return;
    }
    setState(() {
      _unit = unit;
      final canonical = _canonical;
      if (canonical != null && canonical > 0) {
        _speed.text = formatEngineQuantity(displaySpeed(canonical, unit));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reading = interpretOeeEngineText(
      planned: _planned.text,
      downtime: _downtime.text,
      speed: _speed.text,
      speedUnit: _unit,
      total: _total.text,
      good: _good.text,
      canonicalCycle: _canonical,
    );
    final lineName = widget.lineName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lineName == null
              ? 'La velocitat ideal correspon a la línia i l\'article del registre. Aquest pas no tria línia ni article.'
              : 'Línia: $lineName. La velocitat ideal correspon a aquesta línia.',
        ),
        const SizedBox(height: 8),
        _field(
          key: enginePlannedKey,
          controller: _planned,
          focusNode: _plannedFocus,
          label: 'Temps planificat',
          unit: 'min',
          decimal: true,
          hasError: engineFieldHasError(
            OeeEngineField.plannedMinutes,
            reading.issues,
          ),
          onChanged: _changed,
        ),
        _field(
          key: engineDowntimeKey,
          controller: _downtime,
          label: 'Temps de parades',
          unit: 'min',
          decimal: true,
          hasError: engineFieldHasError(
            OeeEngineField.downtimeMinutes,
            reading.issues,
          ),
          onChanged: _changed,
        ),
        _field(
          key: engineSpeedKey,
          controller: _speed,
          label: 'Velocitat',
          unit: speedUnitLabel(_unit),
          decimal: true,
          hasError: engineFieldHasError(OeeEngineField.speed, reading.issues),
          onChanged: _onSpeed,
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: 'Unitat de velocitat. Activa: ${speedUnitLabel(_unit)}.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _unitButton(
                engineUnitSecondsKey,
                SpeedUnit.secondsPerUnit,
                's/unitat',
              ),
              _unitButton(
                engineUnitRateKey,
                SpeedUnit.unitsPerSecond,
                'unitats/s',
              ),
            ],
          ),
        ),
        _field(
          key: engineTotalKey,
          controller: _total,
          label: 'Unitats totals',
          unit: 'unitats',
          decimal: false,
          hasError: engineFieldHasError(
            OeeEngineField.totalUnits,
            reading.issues,
          ),
          onChanged: _changed,
        ),
        _field(
          key: engineGoodKey,
          controller: _good,
          label: 'Unitats bones',
          unit: 'unitats',
          decimal: false,
          hasError: engineFieldHasError(
            OeeEngineField.goodUnits,
            reading.issues,
          ),
          onChanged: _changed,
        ),
        const SizedBox(height: 12),
        _Result(reading: reading),
      ],
    );
  }

  Widget _unitButton(Key key, SpeedUnit unit, String label) {
    final active = _unit == unit;
    return OutlinedButton(
      key: key,
      focusNode: unit == SpeedUnit.unitsPerSecond ? _unitRateFocus : null,
      style: workspaceControlStyle,
      onPressed: () => _setUnit(unit),
      child: Text(active ? 'Activa: $label' : label),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String unit,
    required bool decimal,
    required bool hasError,
    required ValueChanged<String> onChanged,
  }) {
    final border = hasError
        ? const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF8C3A3A), width: 2),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        container: true,
        textField: true,
        label: '$label, $unit',
        child: TextField(
          key: key,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16, height: 1.25),
          decoration: InputDecoration(
            labelText: label,
            suffixText: unit,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.reading});

  final OeeTextResult reading;

  @override
  Widget build(BuildContext context) {
    final outcome = reading.outcome;
    return Card(
      key: engineResultKey,
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fórmula oee.v1',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (outcome != null) ...[
              Text(_factor('Disponibilitat', outcome.availability)),
              Text(_factor('Rendiment', outcome.performance)),
              Text(_factor('Qualitat', outcome.quality)),
              Text(
                'OEE: ${formatOeeEnginePercent(outcome.oee)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final note in outcome.notes)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(note),
                ),
              if (outcome.pie.allowed) ...[
                const SizedBox(height: 12),
                Text(pieExplanation),
                const SizedBox(height: 8),
                _Pie(outcome: outcome),
              ],
            ],
            for (final issue in reading.issues)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  oeeEngineIssueMessage(issue),
                  style: const TextStyle(color: Color(0xFF8C3A3A)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _factor(String label, double? ratio) {
    if (ratio == null) {
      return '$label: no aplica';
    }
    return '$label: ${formatOeeEnginePercent(ratio)}';
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.outcome});

  final OeeEngineOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final slices = outcome.pie.slices;
    final lines = [
      for (final slice in slices)
        '${slice.label} ${formatOeeEngineMinutes(slice.seconds)}',
      'Total ${formatOeeEngineMinutes(outcome.plannedSeconds)}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Pastís del temps planificat. ${lines.join('. ')}.',
          child: SizedBox(
            key: enginePieKey,
            height: 160,
            child: CustomPaint(
              painter: _PiePainter(slices),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        for (final slice in slices)
          Tooltip(
            message: pieSliceTooltip(
              slice,
              formatOeeEngineMinutes(slice.seconds),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _sliceColor(slice.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${slice.label}: ${formatOeeEngineMinutes(slice.seconds)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Total: ${formatOeeEngineMinutes(outcome.plannedSeconds)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter(this.slices);

  final List<OeePieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Rect.fromLTWH(
      (size.width - side) / 2,
      (size.height - side) / 2,
      side,
      side,
    ).deflate(4);
    final sum = slices.fold<double>(0, (total, slice) => total + slice.seconds);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = steel;
    if (sum <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, outline);
      return;
    }
    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.seconds <= 0) {
        continue;
      }
      final sweep = slice.seconds / sum * math.pi * 2;
      final paint = Paint()..color = _sliceColor(slice.id);
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    canvas.drawArc(rect, 0, math.pi * 2, false, outline);
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (var index = 0; index < slices.length; index++) {
      if (oldDelegate.slices[index].seconds != slices[index].seconds ||
          oldDelegate.slices[index].id != slices[index].id) {
        return true;
      }
    }
    return false;
  }
}

Color _sliceColor(String id) {
  switch (id) {
    case 'productive':
      return accent;
    case 'availability':
      return steel;
    case 'performance':
      return const Color(0xFF8C6A3A);
    case 'quality':
      return const Color(0xFF3F6B4E);
    default:
      return steelLine;
  }
}
