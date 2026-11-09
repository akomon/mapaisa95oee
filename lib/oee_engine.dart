// Motor OEE de la secció 5. Sense Flutter.
// Contracte: specs/redesign/phase-d.md

import 'dart:math' as math;

import 'workspace_model.dart';

const String oeeFormulaVersion = 'oee.v1';

const double oeeRelativeTolerance = 1e-9;

enum OeeEngineField {
  plannedMinutes,
  downtimeMinutes,
  speed,
  totalUnits,
  goodUnits,
}

enum OeeEngineIssueCode {
  empty,
  invalidNumber,
  ambiguousThousands,
  notFinite,
  notInteger,
  plannedNotPositive,
  downtimeNegative,
  downtimeExceedsPlanned,
  speedNotPositive,
  totalNegative,
  goodNegative,
  goodExceedsTotal,
  unitMismatch,
  inconsistentOperating,
}

class OeeEngineIssue {
  const OeeEngineIssue({required this.field, required this.code});

  final OeeEngineField field;
  final OeeEngineIssueCode code;
}

class OeeDecimalParse {
  const OeeDecimalParse._({this.value, this.issueCode});

  const OeeDecimalParse.value(double value) : this._(value: value);

  const OeeDecimalParse.issue(OeeEngineIssueCode issueCode)
    : this._(issueCode: issueCode);

  final double? value;
  final OeeEngineIssueCode? issueCode;
}

class OeeIntegerParse {
  const OeeIntegerParse._({this.value, this.issueCode});

  const OeeIntegerParse.value(int value) : this._(value: value);

  const OeeIntegerParse.issue(OeeEngineIssueCode issueCode)
    : this._(issueCode: issueCode);

  final int? value;
  final OeeEngineIssueCode? issueCode;
}

class OeePieSlice {
  const OeePieSlice({
    required this.id,
    required this.label,
    required this.seconds,
  });

  final String id;
  final String label;
  final double seconds;
}

class OeePieDecision {
  const OeePieDecision._({
    required this.allowed,
    required this.normalizedResidue,
    required this.slices,
    required this.note,
  });

  const OeePieDecision.allowed({
    required List<OeePieSlice> slices,
    required bool normalizedResidue,
    String? note,
  }) : this._(
         allowed: true,
         normalizedResidue: normalizedResidue,
         slices: slices,
         note: note,
       );

  const OeePieDecision.blocked(String note)
    : this._(
        allowed: false,
        normalizedResidue: false,
        slices: const [],
        note: note,
      );

  final bool allowed;
  final bool normalizedResidue;
  final List<OeePieSlice> slices;
  final String? note;
}

class OeeEngineInputs {
  const OeeEngineInputs({
    required this.plannedMinutes,
    required this.downtimeMinutes,
    required this.speedOriginal,
    required this.speedUnit,
    required this.totalUnits,
    required this.goodUnits,
    this.idealCycleSeconds,
  });

  final double plannedMinutes;
  final double downtimeMinutes;
  final double speedOriginal;
  final SpeedUnit speedUnit;
  final int totalUnits;
  final int goodUnits;

  /// Si ve informat, ha de coincidir amb [speedOriginal] i [speedUnit].
  /// El càlcul usa aquest double i no el torna a derivar del text.
  final double? idealCycleSeconds;
}

class OeeEngineOutcome {
  const OeeEngineOutcome({
    required this.formulaVersion,
    required this.plannedSeconds,
    required this.downtimeSeconds,
    required this.operatingSeconds,
    required this.idealCycleSeconds,
    required this.speedOriginal,
    required this.speedUnit,
    required this.totalUnits,
    required this.goodUnits,
    required this.availability,
    required this.performance,
    required this.quality,
    required this.oee,
    required this.performanceAboveIdeal,
    required this.allowsDraft,
    required this.allowsValidation,
    required this.pie,
    required this.notes,
  });

  final String formulaVersion;
  final double plannedSeconds;
  final double downtimeSeconds;
  final double operatingSeconds;
  final double idealCycleSeconds;
  final double speedOriginal;
  final SpeedUnit speedUnit;
  final int totalUnits;
  final int goodUnits;
  final double? availability;
  final double? performance;
  final double? quality;
  final double oee;
  final bool performanceAboveIdeal;
  final bool allowsDraft;
  final bool allowsValidation;
  final OeePieDecision pie;
  final List<String> notes;
}

class OeeEngineComputation {
  const OeeEngineComputation.success(this.outcome) : issues = const [];

  const OeeEngineComputation.failure(this.issues) : outcome = null;

  final OeeEngineOutcome? outcome;
  final List<OeeEngineIssue> issues;

  bool get isValid => outcome != null;
}

class OeeTextResult {
  const OeeTextResult({
    required this.issues,
    required this.outcome,
    this.inputs,
  });

  final List<OeeEngineIssue> issues;
  final OeeEngineOutcome? outcome;

  /// Inputs ja parsejats. El registre hi congela P, S i la velocitat original.
  final OeeEngineInputs? inputs;

  bool get isValid => outcome != null;
}

const String pieNegativeMessage =
    'No es dibuixa el pastís: el rendiment superior a 1 deixaria una porció negativa.';

const String pieImbalanceMessage =
    'No es dibuixa el pastís: les dades no descomponen el temps planificat.';

const String pieResidueMessage =
    'Un residu numèric de coma flotant s\'ha normalitzat només en representar el pastís.';

const String qualityNotApplicableMessage =
    'La qualitat no aplica perquè no hi ha unitats produïdes.';

const String performanceNotApplicableMessage =
    'El rendiment no aplica perquè el temps operatiu és zero i no hi ha producció.';

const String performanceAboveIdealMessage =
    'El rendiment supera 1. La velocitat, el temps o les unitats no són coherents. No es capa el factor.';

const String validationBlockedMessage =
    'Es podria desar un esborrany, però no es pot validar. Aquest càlcul no desa cap registre.';

const String calculationNotStoredMessage =
    'Aquest càlcul no desa cap registre.';

const String pieExplanation =
    'Descomposició equivalent del temps planificat, no un registre cronològic de causes de parada. Les unitats es converteixen a temps ideal amb c (segons/unitat).';

bool oeeRelativelyClose(
  double left,
  double right, [
  double tolerance = oeeRelativeTolerance,
]) {
  if (!left.isFinite || !right.isFinite) {
    return false;
  }
  final difference = (left - right).abs();
  final scale = math.max(left.abs(), right.abs());
  if (scale == 0) {
    return difference == 0;
  }
  return difference <= tolerance * scale;
}

double canonicalCycleSeconds(double magnitude, SpeedUnit unit) {
  switch (unit) {
    case SpeedUnit.secondsPerUnit:
      return magnitude;
    case SpeedUnit.unitsPerSecond:
      return 1 / magnitude;
  }
}

double displaySpeed(double cycleSeconds, SpeedUnit unit) {
  switch (unit) {
    case SpeedUnit.secondsPerUnit:
      return cycleSeconds;
    case SpeedUnit.unitsPerSecond:
      return 1 / cycleSeconds;
  }
}

String formatEngineQuantity(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'cal un nombre finit');
  }
  final text = value.toString();
  if (!text.contains('e') && !text.contains('E')) {
    return text;
  }
  final plain = value.toStringAsFixed(12);
  final negative = plain.startsWith('-');
  final body = negative ? plain.substring(1) : plain;
  final parts = body.split('.');
  var fraction = parts[1];
  while (fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }
  final number = fraction.isEmpty ? parts[0] : '${parts[0]}.$fraction';
  return negative ? '-$number' : number;
}

OeeDecimalParse parseOeeEngineDecimal(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.empty);
  }
  if (_isNonFiniteToken(trimmed)) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.notFinite);
  }
  final separators = _separatorCount(trimmed);
  if (separators > 1) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.ambiguousThousands);
  }
  if (trimmed.contains(' ') || trimmed.contains('e') || trimmed.contains('E')) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.invalidNumber);
  }
  final normalized = trimmed.replaceAll(',', '.');
  if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(normalized)) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.invalidNumber);
  }
  final value = double.parse(normalized);
  if (!value.isFinite) {
    return const OeeDecimalParse.issue(OeeEngineIssueCode.notFinite);
  }
  return OeeDecimalParse.value(value);
}

OeeIntegerParse parseOeeEngineInteger(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const OeeIntegerParse.issue(OeeEngineIssueCode.empty);
  }
  if (_isNonFiniteToken(trimmed)) {
    return const OeeIntegerParse.issue(OeeEngineIssueCode.notFinite);
  }
  if (trimmed.contains('.') ||
      trimmed.contains(',') ||
      trimmed.contains(' ') ||
      trimmed.contains('e') ||
      trimmed.contains('E')) {
    return const OeeIntegerParse.issue(OeeEngineIssueCode.notInteger);
  }
  if (!RegExp(r'^[+-]?\d+$').hasMatch(trimmed)) {
    return const OeeIntegerParse.issue(OeeEngineIssueCode.notInteger);
  }
  return OeeIntegerParse.value(int.parse(trimmed));
}

OeeTextResult interpretOeeEngineText({
  required String planned,
  required String downtime,
  required String speed,
  required SpeedUnit speedUnit,
  required String total,
  required String good,
  double? canonicalCycle,
}) {
  final plannedParse = parseOeeEngineDecimal(planned);
  final downtimeParse = parseOeeEngineDecimal(downtime);
  final speedParse = parseOeeEngineDecimal(speed);
  final totalParse = parseOeeEngineInteger(total);
  final goodParse = parseOeeEngineInteger(good);
  final issues = <OeeEngineIssue>[
    if (plannedParse.issueCode != null)
      OeeEngineIssue(
        field: OeeEngineField.plannedMinutes,
        code: plannedParse.issueCode!,
      ),
    if (downtimeParse.issueCode != null)
      OeeEngineIssue(
        field: OeeEngineField.downtimeMinutes,
        code: downtimeParse.issueCode!,
      ),
    if (speedParse.issueCode != null)
      OeeEngineIssue(field: OeeEngineField.speed, code: speedParse.issueCode!),
    if (totalParse.issueCode != null)
      OeeEngineIssue(
        field: OeeEngineField.totalUnits,
        code: totalParse.issueCode!,
      ),
    if (goodParse.issueCode != null)
      OeeEngineIssue(
        field: OeeEngineField.goodUnits,
        code: goodParse.issueCode!,
      ),
  ];
  if (issues.isNotEmpty) {
    return OeeTextResult(issues: issues, outcome: null);
  }

  final speedValue = speedParse.value!;
  double? ideal;
  if (canonicalCycle != null && speedValue > 0) {
    final derived = canonicalCycleSeconds(speedValue, speedUnit);
    if (derived.isFinite && oeeRelativelyClose(derived, canonicalCycle)) {
      ideal = canonicalCycle;
    }
  }
  final inputs = OeeEngineInputs(
    plannedMinutes: plannedParse.value!,
    downtimeMinutes: downtimeParse.value!,
    speedOriginal: speedValue,
    speedUnit: speedUnit,
    totalUnits: totalParse.value!,
    goodUnits: goodParse.value!,
    idealCycleSeconds: ideal,
  );
  final computation = evaluateOeeEngine(inputs);
  return OeeTextResult(
    issues: computation.issues,
    outcome: computation.outcome,
    inputs: inputs,
  );
}

OeeEngineComputation evaluateOeeEngine(OeeEngineInputs inputs) {
  final issues = <OeeEngineIssue>[];
  if (!inputs.plannedMinutes.isFinite) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.plannedMinutes,
        code: OeeEngineIssueCode.notFinite,
      ),
    );
  } else if (inputs.plannedMinutes <= 0) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.plannedMinutes,
        code: OeeEngineIssueCode.plannedNotPositive,
      ),
    );
  }
  if (!inputs.downtimeMinutes.isFinite) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.downtimeMinutes,
        code: OeeEngineIssueCode.notFinite,
      ),
    );
  } else if (inputs.downtimeMinutes < 0) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.downtimeMinutes,
        code: OeeEngineIssueCode.downtimeNegative,
      ),
    );
  } else if (inputs.plannedMinutes.isFinite &&
      inputs.downtimeMinutes > inputs.plannedMinutes) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.downtimeMinutes,
        code: OeeEngineIssueCode.downtimeExceedsPlanned,
      ),
    );
  }

  double? cycle;
  if (!inputs.speedOriginal.isFinite) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.speed,
        code: OeeEngineIssueCode.notFinite,
      ),
    );
  } else if (inputs.speedOriginal <= 0) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.speed,
        code: OeeEngineIssueCode.speedNotPositive,
      ),
    );
  } else if (inputs.idealCycleSeconds != null) {
    final claimed = inputs.idealCycleSeconds!;
    final derived = canonicalCycleSeconds(
      inputs.speedOriginal,
      inputs.speedUnit,
    );
    if (!claimed.isFinite ||
        !derived.isFinite ||
        !oeeRelativelyClose(derived, claimed)) {
      issues.add(
        const OeeEngineIssue(
          field: OeeEngineField.speed,
          code: OeeEngineIssueCode.unitMismatch,
        ),
      );
    } else {
      cycle = claimed;
    }
  } else {
    final derived = canonicalCycleSeconds(
      inputs.speedOriginal,
      inputs.speedUnit,
    );
    if (!derived.isFinite || derived <= 0) {
      issues.add(
        const OeeEngineIssue(
          field: OeeEngineField.speed,
          code: OeeEngineIssueCode.speedNotPositive,
        ),
      );
    } else {
      cycle = derived;
    }
  }

  if (inputs.totalUnits < 0) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.totalUnits,
        code: OeeEngineIssueCode.totalNegative,
      ),
    );
  }
  if (inputs.goodUnits < 0) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.goodUnits,
        code: OeeEngineIssueCode.goodNegative,
      ),
    );
  } else if (inputs.totalUnits >= 0 && inputs.goodUnits > inputs.totalUnits) {
    issues.add(
      const OeeEngineIssue(
        field: OeeEngineField.goodUnits,
        code: OeeEngineIssueCode.goodExceedsTotal,
      ),
    );
  }
  if (issues.isNotEmpty) {
    return OeeEngineComputation.failure(issues);
  }

  final plannedSeconds = inputs.plannedMinutes * 60;
  final downtimeSeconds = inputs.downtimeMinutes * 60;
  final operatingSeconds = plannedSeconds - downtimeSeconds;
  if (operatingSeconds == 0 && inputs.totalUnits > 0) {
    return const OeeEngineComputation.failure([
      OeeEngineIssue(
        field: OeeEngineField.totalUnits,
        code: OeeEngineIssueCode.inconsistentOperating,
      ),
    ]);
  }

  final ideal = cycle!;
  final total = inputs.totalUnits;
  final good = inputs.goodUnits;
  final availability = operatingSeconds / plannedSeconds;
  final double? performance = operatingSeconds > 0
      ? (ideal * total) / operatingSeconds
      : null;
  final double? quality = total > 0 ? good / total : null;
  final oee = (ideal * good) / plannedSeconds;
  final above =
      performance != null &&
      performance > 1 &&
      !oeeRelativelyClose(performance, 1);
  final pie = decidePlannedTimePie(
    plannedSeconds: plannedSeconds,
    productiveSeconds: ideal * good,
    availabilitySeconds: downtimeSeconds,
    performanceSeconds: operatingSeconds - (ideal * total),
    qualitySeconds: ideal * (total - good),
  );
  final notes = <String>[
    if (quality == null) qualityNotApplicableMessage,
    if (performance == null) performanceNotApplicableMessage,
    if (above) performanceAboveIdealMessage,
    if (above) validationBlockedMessage,
    if (!above) calculationNotStoredMessage,
    if (pie.normalizedResidue && pie.note != null) pie.note!,
    if (!pie.allowed && pie.note != null) pie.note!,
  ];
  return OeeEngineComputation.success(
    OeeEngineOutcome(
      formulaVersion: oeeFormulaVersion,
      plannedSeconds: plannedSeconds,
      downtimeSeconds: downtimeSeconds,
      operatingSeconds: operatingSeconds,
      idealCycleSeconds: ideal,
      speedOriginal: inputs.speedOriginal,
      speedUnit: inputs.speedUnit,
      totalUnits: total,
      goodUnits: good,
      availability: availability,
      performance: performance,
      quality: quality,
      oee: oee,
      performanceAboveIdeal: above,
      allowsDraft: true,
      allowsValidation: !above && pie.allowed,
      pie: pie,
      notes: notes,
    ),
  );
}

OeePieDecision decidePlannedTimePie({
  required double plannedSeconds,
  required double productiveSeconds,
  required double availabilitySeconds,
  required double performanceSeconds,
  required double qualitySeconds,
}) {
  final raw = <double>[
    productiveSeconds,
    availabilitySeconds,
    performanceSeconds,
    qualitySeconds,
  ];
  if (!plannedSeconds.isFinite ||
      plannedSeconds <= 0 ||
      raw.any((value) => !value.isFinite)) {
    return const OeePieDecision.blocked(pieImbalanceMessage);
  }
  final limit = oeeRelativeTolerance * plannedSeconds.abs();
  if (raw.any((value) => value < -limit)) {
    return const OeePieDecision.blocked(pieNegativeMessage);
  }
  var residue = false;
  final adjusted = <double>[];
  for (final value in raw) {
    if (value < 0) {
      residue = true;
      adjusted.add(0);
    } else {
      adjusted.add(value);
    }
  }
  final sum = adjusted.fold<double>(0, (total, value) => total + value);
  if (!oeeRelativelyClose(sum, plannedSeconds)) {
    return const OeePieDecision.blocked(pieImbalanceMessage);
  }
  if (sum != plannedSeconds) {
    residue = true;
  }
  const labels = <(String, String)>[
    ('productive', 'Productiu'),
    ('availability', 'Disponibilitat'),
    ('performance', 'Rendiment'),
    ('quality', 'Qualitat'),
  ];
  return OeePieDecision.allowed(
    normalizedResidue: residue,
    note: residue ? pieResidueMessage : null,
    slices: [
      for (var index = 0; index < labels.length; index++)
        OeePieSlice(
          id: labels[index].$1,
          label: labels[index].$2,
          seconds: adjusted[index],
        ),
    ],
  );
}

String formatOeeEnginePercent(double ratio) {
  if (!ratio.isFinite) {
    throw ArgumentError.value(ratio, 'ratio', 'cal un nombre finit');
  }
  final negative = ratio < 0;
  final scaled = ratio.abs() * 100000000;
  final nudged = scaled + 1e-4;
  final rounded = nudged.round();
  final digits = rounded.toString().padLeft(7, '0');
  final whole = digits.substring(0, digits.length - 6);
  var fraction = digits.substring(digits.length - 6);
  while (fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }
  final number = fraction.isEmpty ? whole : '$whole.$fraction';
  return '${negative ? '-' : ''}$number %';
}

String formatOeeEngineMinutes(double seconds) {
  if (!seconds.isFinite) {
    throw ArgumentError.value(seconds, 'seconds', 'cal un nombre finit');
  }
  final minutes = seconds / 60;
  final nearest = minutes.roundToDouble();
  if (oeeRelativelyClose(minutes, nearest) && nearest.abs() < 1000000000000) {
    return '${nearest.round()} min';
  }
  return '${_trimFixed(minutes, 6)} min';
}

String oeeEngineFieldLabel(OeeEngineField field) {
  switch (field) {
    case OeeEngineField.plannedMinutes:
      return 'Temps planificat';
    case OeeEngineField.downtimeMinutes:
      return 'Temps de parades';
    case OeeEngineField.speed:
      return 'Velocitat';
    case OeeEngineField.totalUnits:
      return 'Unitats totals';
    case OeeEngineField.goodUnits:
      return 'Unitats bones';
  }
}

String oeeEngineIssueMessage(OeeEngineIssue issue) {
  switch (issue.code) {
    case OeeEngineIssueCode.empty:
      return switch (issue.field) {
        OeeEngineField.plannedMinutes => 'El temps planificat és obligatori.',
        OeeEngineField.downtimeMinutes => 'El temps de parades és obligatori.',
        OeeEngineField.speed => 'La velocitat és obligatòria.',
        OeeEngineField.totalUnits => 'Les unitats totals són obligatòries.',
        OeeEngineField.goodUnits => 'Les unitats bones són obligatòries.',
      };
    case OeeEngineIssueCode.invalidNumber:
      return switch (issue.field) {
        OeeEngineField.plannedMinutes =>
          'El temps planificat no és un nombre vàlid.',
        OeeEngineField.downtimeMinutes =>
          'El temps de parades no és un nombre vàlid.',
        OeeEngineField.speed => 'La velocitat no és un nombre vàlid.',
        OeeEngineField.totalUnits => 'Les unitats totals han de ser un enter, sense decimals ni separadors de milers.',
        OeeEngineField.goodUnits => 'Les unitats bones han de ser un enter, sense decimals ni separadors de milers.',
      };
    case OeeEngineIssueCode.ambiguousThousands:
      return switch (issue.field) {
        OeeEngineField.plannedMinutes =>
          'El temps planificat té separadors de milers ambigus.',
        OeeEngineField.downtimeMinutes =>
          'El temps de parades té separadors de milers ambigus.',
        OeeEngineField.speed => 'La velocitat té separadors de milers ambigus.',
        OeeEngineField.totalUnits || OeeEngineField.goodUnits => 'Les unitats han de ser un enter, sense decimals ni separadors de milers.',
      };
    case OeeEngineIssueCode.notFinite:
      return switch (issue.field) {
        OeeEngineField.plannedMinutes =>
          'El temps planificat no és un nombre finit.',
        OeeEngineField.downtimeMinutes =>
          'El temps de parades no és un nombre finit.',
        OeeEngineField.speed => 'La velocitat no és un nombre finit.',
        OeeEngineField.totalUnits =>
          'Les unitats totals no són un nombre finit.',
        OeeEngineField.goodUnits => 'Les unitats bones no són un nombre finit.',
      };
    case OeeEngineIssueCode.notInteger:
      return switch (issue.field) {
        OeeEngineField.totalUnits => 'Les unitats totals han de ser un enter, sense decimals ni separadors de milers.',
        OeeEngineField.goodUnits => 'Les unitats bones han de ser un enter, sense decimals ni separadors de milers.',
        _ => 'Cal un enter.',
      };
    case OeeEngineIssueCode.plannedNotPositive:
      return 'El temps planificat ha de ser més gran que zero.';
    case OeeEngineIssueCode.downtimeNegative:
      return 'El temps de parades no pot ser negatiu.';
    case OeeEngineIssueCode.downtimeExceedsPlanned:
      return 'El temps de parades no pot superar el temps planificat.';
    case OeeEngineIssueCode.speedNotPositive:
      return 'La velocitat ha de ser més gran que zero.';
    case OeeEngineIssueCode.totalNegative:
      return 'Les unitats totals no poden ser negatives.';
    case OeeEngineIssueCode.goodNegative:
      return 'Les unitats bones no poden ser negatives.';
    case OeeEngineIssueCode.goodExceedsTotal:
      return 'Les unitats bones no poden superar les unitats totals.';
    case OeeEngineIssueCode.unitMismatch:
      return 'La unitat de la velocitat no coincideix amb el cicle canònic. No es fa cap conversió silenciosa.';
    case OeeEngineIssueCode.inconsistentOperating:
      return 'No hi pot haver producció amb temps operatiu zero.';
  }
}

String speedUnitLabel(SpeedUnit unit) {
  switch (unit) {
    case SpeedUnit.secondsPerUnit:
      return 's/unitat';
    case SpeedUnit.unitsPerSecond:
      return 'unitats/s';
  }
}

String pieSliceTooltip(OeePieSlice slice, String minutesLabel) {
  final detail = switch (slice.id) {
    'productive' =>
      'Temps ideal de les unitats bones (c × G). No és un interval cronològic.',
    'availability' => 'Parades dins del temps planificat.',
    'performance' => 'Temps operatiu no aprofitat al ritme ideal (O − c × N).',
    'quality' => 'Temps ideal de les unitats no bones (c × (N − G)).',
    _ => pieExplanation,
  };
  return '$minutesLabel. $detail';
}

bool engineFieldHasError(OeeEngineField field, List<OeeEngineIssue> issues) {
  if (issues.any((issue) => issue.field == field)) {
    return true;
  }
  return field == OeeEngineField.downtimeMinutes &&
      issues.any(
        (issue) => issue.code == OeeEngineIssueCode.inconsistentOperating,
      );
}

bool _isNonFiniteToken(String raw) {
  switch (raw.toLowerCase()) {
    case 'nan':
    case '+nan':
    case '-nan':
    case 'infinity':
    case '+infinity':
    case '-infinity':
    case 'inf':
    case '+inf':
    case '-inf':
      return true;
    default:
      return false;
  }
}

int _separatorCount(String raw) {
  return '.'.allMatches(raw).length + ','.allMatches(raw).length;
}

String _trimFixed(double value, int decimals) {
  final negative = value < 0;
  final factor = math.pow(10, decimals).toDouble();
  final scaled = value.abs() * factor + 1e-6;
  final rounded = scaled.round();
  final digits = rounded.toString().padLeft(decimals + 1, '0');
  final whole = digits.substring(0, digits.length - decimals);
  var fraction = digits.substring(digits.length - decimals);
  while (fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }
  final number = fraction.isEmpty ? whole : '$whole.$fraction';
  return negative ? '-$number' : number;
}
