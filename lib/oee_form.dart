import 'package:flutter/material.dart';

import 'oee_calculator.dart';

const Key plannedMinutesKey = Key('plannedMinutes');
const Key downtimeMinutesKey = Key('downtimeMinutes');
const Key idealCycleSecondsKey = Key('idealCycleSeconds');
const Key totalUnitsKey = Key('totalUnits');
const Key goodUnitsKey = Key('goodUnits');

class OeeForm extends StatefulWidget {
  const OeeForm({super.key, this.onOpenMap});

  final VoidCallback? onOpenMap;

  @override
  State<OeeForm> createState() => _OeeFormState();
}

class _OeeFormState extends State<OeeForm> {
  final TextEditingController _planned = TextEditingController();
  final TextEditingController _downtime = TextEditingController();
  final TextEditingController _cycle = TextEditingController();
  final TextEditingController _total = TextEditingController();
  final TextEditingController _good = TextEditingController();

  @override
  void dispose() {
    _planned.dispose();
    _downtime.dispose();
    _cycle.dispose();
    _total.dispose();
    _good.dispose();
    super.dispose();
  }

  void _changed(String _) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final model = _evaluate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculador OEE'),
        actions: [
          if (widget.onOpenMap != null)
            TextButton(
              onPressed: widget.onOpenMap,
              child: const Text('Mapa ISA-95'),
            ),
        ],
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
                  _NumberField(
                    fieldKey: plannedMinutesKey,
                    controller: _planned,
                    label: 'Temps planificat',
                    unit: 'min',
                    hasError: model.fieldHasError(_FieldId.planned),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    fieldKey: downtimeMinutesKey,
                    controller: _downtime,
                    label: 'Temps de parades',
                    unit: 'min',
                    hasError: model.fieldHasError(_FieldId.downtime),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    fieldKey: idealCycleSecondsKey,
                    controller: _cycle,
                    label: 'Temps de cicle ideal',
                    unit: 's/unitat',
                    hasError: model.fieldHasError(_FieldId.cycle),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    fieldKey: totalUnitsKey,
                    controller: _total,
                    label: 'Unitats totals',
                    unit: 'unitats',
                    hasError: model.fieldHasError(_FieldId.total),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    fieldKey: goodUnitsKey,
                    controller: _good,
                    label: 'Unitats bones',
                    unit: 'unitats',
                    hasError: model.fieldHasError(_FieldId.good),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 16),
                  _ResultPanel(model: model),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _FormModel _evaluate() {
    final fields = <_FieldId, _ParsedField>{
      _FieldId.planned: _parse(_planned.text),
      _FieldId.downtime: _parse(_downtime.text),
      _FieldId.cycle: _parse(_cycle.text),
      _FieldId.total: _parse(_total.text),
      _FieldId.good: _parse(_good.text),
    };
    final issues = <OeeIssueCode>[];
    if (fields.values.any((field) => field.invalid)) {
      issues.add(OeeIssueCode.invalidNumber);
    }

    final complete = fields.values.every((field) => field.value != null);
    OeeResult? result;
    if (complete) {
      final computation = calculateOee(
        OeeInputs(
          plannedMinutes: fields[_FieldId.planned]!.value!,
          downtimeMinutes: fields[_FieldId.downtime]!.value!,
          idealCycleSeconds: fields[_FieldId.cycle]!.value!,
          totalUnits: fields[_FieldId.total]!.value!,
          goodUnits: fields[_FieldId.good]!.value!,
        ),
      );
      issues.addAll(computation.issues);
      result = computation.result;
    } else if (fields.values.any((field) => field.isNegative)) {
      issues.add(OeeIssueCode.negativeValue);
    }

    final messages = <String>[
      for (final code in issues) oeeIssueMessage(code),
      if (fields.values.any((field) => field.empty)) incompleteOeeMessage,
    ];
    return _FormModel(
      fields: fields,
      issues: issues,
      messages: messages,
      result: result,
    );
  }
}

enum _FieldId { planned, downtime, cycle, total, good }

class _ParsedField {
  const _ParsedField._({this.value, this.invalid = false, this.empty = false});

  const _ParsedField.empty() : this._(empty: true);

  const _ParsedField.invalid() : this._(invalid: true);

  const _ParsedField.parsed(double value) : this._(value: value);

  final double? value;
  final bool invalid;
  final bool empty;

  bool get isNegative => value != null && value! < 0;
}

_ParsedField _parse(String raw) {
  try {
    final value = parseOeeDecimal(raw);
    if (value == null) {
      return const _ParsedField.empty();
    }
    return _ParsedField.parsed(value);
  } on FormatException {
    return const _ParsedField.invalid();
  }
}

class _FormModel {
  const _FormModel({
    required this.fields,
    required this.issues,
    required this.messages,
    required this.result,
  });

  final Map<_FieldId, _ParsedField> fields;
  final List<OeeIssueCode> issues;
  final List<String> messages;
  final OeeResult? result;

  bool fieldHasError(_FieldId id) {
    final field = fields[id]!;
    if (field.invalid || field.isNegative) {
      return true;
    }
    return switch (id) {
      _FieldId.planned =>
        issues.contains(OeeIssueCode.plannedTimeZero) ||
            issues.contains(OeeIssueCode.operatingTimeZero),
      _FieldId.downtime =>
        issues.contains(OeeIssueCode.downtimeExceedsPlanned) ||
            issues.contains(OeeIssueCode.operatingTimeZero),
      _FieldId.cycle => false,
      _FieldId.total => issues.contains(OeeIssueCode.totalUnitsZero),
      _FieldId.good => issues.contains(OeeIssueCode.goodExceedsTotal),
    };
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
    required this.hasError,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = hasError ? scheme.error : scheme.outline;
    final focusedColor = hasError ? scheme.error : scheme.primary;
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 16, height: 1.25),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: focusedColor, width: 2),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.model});

  final _FormModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = model.result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultat', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result != null) ...[
              Text(
                'OEE: ${formatOeePercent(result.oee)}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_factorLine(OeeFactor.availability, result.availability)),
              Text(_factorLine(OeeFactor.performance, result.performance)),
              Text(_factorLine(OeeFactor.quality, result.quality)),
              const SizedBox(height: 8),
              Text(
                mainLossMessage(result.mainLosses),
                style: theme.textTheme.titleSmall,
              ),
              if (result.performanceAboveIdeal) ...[
                const SizedBox(height: 8),
                Text(
                  performanceWarningMessage,
                  style: TextStyle(color: theme.colorScheme.tertiary),
                ),
              ],
            ],
            for (final message in model.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message == incompleteOeeMessage
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _factorLine(OeeFactor factor, double ratio) {
    return '${oeeFactorLabel(factor)}: ${formatOeePercent(ratio)}';
  }
}
