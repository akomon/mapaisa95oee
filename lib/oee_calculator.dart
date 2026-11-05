// Càlcul pur de l'OEE d'un torn. Sense dependències de Flutter.
// Fórmules, missatges i arrodoniment: specs/01-calculador-oee/spec.md.

enum OeeFactor { availability, performance, quality }

enum OeeIssueCode {
  invalidNumber,
  negativeValue,
  goodExceedsTotal,
  downtimeExceedsPlanned,
  plannedTimeZero,
  operatingTimeZero,
  totalUnitsZero,
}

const String incompleteOeeMessage = 'Introdueix totes les dades del torn.';

const String performanceWarningMessage =
    'El rendiment supera el 100 %. Revisa el temps de cicle ideal.';

class OeeInputs {
  const OeeInputs({
    required this.plannedMinutes,
    required this.downtimeMinutes,
    required this.idealCycleSeconds,
    required this.totalUnits,
    required this.goodUnits,
  });

  final double plannedMinutes;
  final double downtimeMinutes;
  final double idealCycleSeconds;
  final double totalUnits;
  final double goodUnits;
}

class OeeResult {
  const OeeResult({
    required this.availability,
    required this.performance,
    required this.quality,
    required this.oee,
    required this.mainLosses,
    required this.performanceAboveIdeal,
  });

  /// Raó (1 = 100 %). El rendiment i l'OEE poden superar 1.
  final double availability;
  final double performance;
  final double quality;
  final double oee;

  /// Factors amb el percentatge arrodonit més baix, en ordre fix.
  final List<OeeFactor> mainLosses;

  final bool performanceAboveIdeal;
}

class OeeComputation {
  const OeeComputation.success(this.result) : issues = const [];

  const OeeComputation.failure(this.issues) : result = null;

  final OeeResult? result;
  final List<OeeIssueCode> issues;

  bool get isValid => result != null;
}

final RegExp _decimalPattern = RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$');

/// Retorna `null` si el text és buit. Llança [FormatException] si no és decimal.
double? parseOeeDecimal(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  if (!_decimalPattern.hasMatch(normalized)) {
    throw const FormatException('invalid number');
  }
  final value = double.parse(normalized);
  if (!value.isFinite) {
    throw const FormatException('invalid number');
  }
  return value;
}

/// Percentatge amb 1 decimal, half-away-from-zero. Exemple: `87.5 %`.
String formatOeePercent(double ratio) {
  final rounded = _roundedTenths(ratio);
  final negative = rounded < 0;
  final absolute = rounded.abs();
  final whole = absolute ~/ 10;
  final fraction = absolute % 10;
  final sign = negative ? '-' : '';
  return '$sign$whole.$fraction %';
}

OeeComputation calculateOee(OeeInputs inputs) {
  final values = <double>[
    inputs.plannedMinutes,
    inputs.downtimeMinutes,
    inputs.idealCycleSeconds,
    inputs.totalUnits,
    inputs.goodUnits,
  ];
  if (values.any((value) => !value.isFinite)) {
    return const OeeComputation.failure([OeeIssueCode.invalidNumber]);
  }
  if (values.any((value) => value < 0)) {
    return const OeeComputation.failure([OeeIssueCode.negativeValue]);
  }

  final issues = <OeeIssueCode>[];
  if (inputs.goodUnits > inputs.totalUnits) {
    issues.add(OeeIssueCode.goodExceedsTotal);
  }
  if (inputs.downtimeMinutes > inputs.plannedMinutes) {
    issues.add(OeeIssueCode.downtimeExceedsPlanned);
  }
  if (inputs.plannedMinutes == 0) {
    issues.add(OeeIssueCode.plannedTimeZero);
  }
  final operatingMinutes = inputs.plannedMinutes - inputs.downtimeMinutes;
  if (inputs.plannedMinutes > 0 && operatingMinutes == 0) {
    issues.add(OeeIssueCode.operatingTimeZero);
  }
  if (inputs.totalUnits == 0) {
    issues.add(OeeIssueCode.totalUnitsZero);
  }
  if (issues.isNotEmpty) {
    return OeeComputation.failure(issues);
  }

  final operatingSeconds = operatingMinutes * 60;
  final availability = operatingMinutes / inputs.plannedMinutes;
  final performance =
      (inputs.idealCycleSeconds * inputs.totalUnits) / operatingSeconds;
  final quality = inputs.goodUnits / inputs.totalUnits;
  final oee = availability * performance * quality;

  final rounded = <OeeFactor, int>{
    OeeFactor.availability: _roundedTenths(availability),
    OeeFactor.performance: _roundedTenths(performance),
    OeeFactor.quality: _roundedTenths(quality),
  };
  final lowest = rounded.values.reduce(
    (left, right) => left < right ? left : right,
  );
  final mainLosses = <OeeFactor>[
    for (final factor in OeeFactor.values)
      if (rounded[factor] == lowest) factor,
  ];

  return OeeComputation.success(
    OeeResult(
      availability: availability,
      performance: performance,
      quality: quality,
      oee: oee,
      mainLosses: mainLosses,
      performanceAboveIdeal: rounded[OeeFactor.performance]! > 1000,
    ),
  );
}

String oeeIssueMessage(OeeIssueCode code) {
  switch (code) {
    case OeeIssueCode.invalidNumber:
      return 'Introdueix un nombre vàlid.';
    case OeeIssueCode.negativeValue:
      return 'Els valors no poden ser negatius.';
    case OeeIssueCode.goodExceedsTotal:
      return 'Les unitats bones no poden superar les unitats totals.';
    case OeeIssueCode.downtimeExceedsPlanned:
      return 'El temps de parades no pot superar el temps planificat.';
    case OeeIssueCode.plannedTimeZero:
      return 'El temps planificat ha de ser més gran que zero.';
    case OeeIssueCode.operatingTimeZero:
      return 'El temps operatiu és zero; no es pot calcular el rendiment.';
    case OeeIssueCode.totalUnitsZero:
      return 'Les unitats totals han de ser més grans que zero.';
  }
}

String oeeFactorLabel(OeeFactor factor) {
  switch (factor) {
    case OeeFactor.availability:
      return 'Disponibilitat';
    case OeeFactor.performance:
      return 'Rendiment';
    case OeeFactor.quality:
      return 'Qualitat';
  }
}

String mainLossMessage(List<OeeFactor> factors) {
  final labels = <String>[
    for (final factor in OeeFactor.values)
      if (factors.contains(factor)) oeeFactorLabel(factor),
  ];
  if (labels.isEmpty) {
    throw ArgumentError.value(factors, 'factors', 'cal almenys un factor');
  }
  final joined = switch (labels.length) {
    1 => labels.single,
    2 => '${labels[0]} i ${labels[1]}',
    _ => '${labels.sublist(0, labels.length - 1).join(', ')} i ${labels.last}',
  };
  return 'Pèrdua principal: $joined.';
}

/// Dècimes de percentatge (87.5 % → 875), half-away-from-zero.
int _roundedTenths(double ratio) {
  final scaled = ratio * 1000;
  final adjusted = scaled.isNegative ? scaled - 1e-9 : scaled + 1e-9;
  return adjusted.round();
}
