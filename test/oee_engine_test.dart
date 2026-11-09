import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/oee_calculator.dart';
import 'package:mapaisa95oee/oee_engine.dart';
import 'package:mapaisa95oee/workspace_model.dart';

void main() {
  OeeEngineInputs reference({
    double plannedMinutes = 480,
    double downtimeMinutes = 60,
    double speedOriginal = 1,
    SpeedUnit speedUnit = SpeedUnit.secondsPerUnit,
    double? idealCycleSeconds = 1,
    int totalUnits = 24000,
    int goodUnits = 22800,
  }) {
    return OeeEngineInputs(
      plannedMinutes: plannedMinutes,
      downtimeMinutes: downtimeMinutes,
      speedOriginal: speedOriginal,
      speedUnit: speedUnit,
      idealCycleSeconds: idealCycleSeconds,
      totalUnits: totalUnits,
      goodUnits: goodUnits,
    );
  }

  OeeEngineOutcome outcomeOf(OeeEngineInputs inputs) {
    final computation = evaluateOeeEngine(inputs);
    expect(computation.issues, isEmpty, reason: '${computation.issues}');
    return computation.outcome!;
  }

  test('la referència de la secció 5 no és el 79.2 % del calculador US-1', () {
    final legacy = calculateOee(
      const OeeInputs(
        plannedMinutes: 480,
        downtimeMinutes: 60,
        idealCycleSeconds: 60,
        totalUnits: 400,
        goodUnits: 380,
      ),
    );
    expect(formatOeePercent(legacy.result!.oee), '79.2 %');

    final result = outcomeOf(reference());
    expect(result.formulaVersion, 'oee.v1');
    expect(result.operatingSeconds, 25200);
    expect(result.idealCycleSeconds, 1);
    expect(result.availability, closeTo(0.875, 1e-12));
    expect(result.performance, closeTo(24000 / 25200, 1e-12));
    expect(result.quality, closeTo(0.95, 1e-12));
    expect(result.oee, closeTo(22800 / 28800, 1e-12));
    expect(
      result.oee,
      closeTo(
        result.availability! * result.performance! * result.quality!,
        1e-12,
      ),
    );
    expect(formatOeeEnginePercent(result.availability!), '87.5 %');
    expect(formatOeeEnginePercent(result.performance!), '95.238095 %');
    expect(formatOeeEnginePercent(result.quality!), '95 %');
    expect(formatOeeEnginePercent(result.oee), '79.166667 %');
    expect(result.performanceAboveIdeal, isFalse);
    expect(result.allowsValidation, isTrue);
    expect(result.pie.allowed, isTrue);
    expect(result.pie.normalizedResidue, isFalse);
    expect(
      [
        for (final slice in result.pie.slices)
          formatOeeEngineMinutes(slice.seconds),
      ],
      ['380 min', '60 min', '20 min', '20 min'],
    );
    expect(formatOeeEngineMinutes(result.plannedSeconds), '480 min');
    final sum = result.pie.slices.fold<double>(
      0,
      (total, slice) => total + slice.seconds,
    );
    expect(sum, result.plannedSeconds);
  });

  test('0,4 s/u i 2,5 u/s són el mateix c i el mateix OEE', () {
    const cycle = 0.4;
    var canonical = cycle;
    for (var turn = 0; turn < 12; turn++) {
      final unit = turn.isEven
          ? SpeedUnit.unitsPerSecond
          : SpeedUnit.secondsPerUnit;
      final shown = displaySpeed(cycle, unit);
      canonical = canonicalCycleSeconds(shown, unit);
      expect(oeeRelativelyClose(canonical, cycle), isTrue);
    }

    final fromCycle = outcomeOf(
      reference(
        plannedMinutes: 1,
        downtimeMinutes: 0,
        speedOriginal: 0.4,
        speedUnit: SpeedUnit.secondsPerUnit,
        idealCycleSeconds: 0.4,
        totalUnits: 100,
        goodUnits: 90,
      ),
    );
    final fromRate = outcomeOf(
      reference(
        plannedMinutes: 1,
        downtimeMinutes: 0,
        speedOriginal: 2.5,
        speedUnit: SpeedUnit.unitsPerSecond,
        idealCycleSeconds: 0.4,
        totalUnits: 100,
        goodUnits: 90,
      ),
    );
    expect(oeeRelativelyClose(fromCycle.idealCycleSeconds, 0.4), isTrue);
    expect(oeeRelativelyClose(fromRate.idealCycleSeconds, 0.4), isTrue);
    expect(formatOeeEnginePercent(fromCycle.availability!), '100 %');
    expect(formatOeeEnginePercent(fromCycle.performance!), '66.666667 %');
    expect(formatOeeEnginePercent(fromCycle.quality!), '90 %');
    expect(formatOeeEnginePercent(fromCycle.oee), '60 %');
    expect(fromRate.oee, closeTo(fromCycle.oee, 1e-12));
  });

  test('el text convertit no substitueix el c canònic', () {
    const canonical = 0.4;
    final shown = formatEngineQuantity(
      displaySpeed(canonical, SpeedUnit.unitsPerSecond),
    );
    final parsed = parseOeeEngineDecimal(shown).value!;
    final reading = interpretOeeEngineText(
      planned: '1',
      downtime: '0',
      speed: shown,
      speedUnit: SpeedUnit.unitsPerSecond,
      total: '100',
      good: '90',
      canonicalCycle: canonical,
    );
    expect(parsed, 2.5);
    expect(reading.outcome!.idealCycleSeconds, canonical);
    expect(formatOeeEnginePercent(reading.outcome!.oee), '60 %');
  });

  test('una unitat que no lliga amb c no es converteix en silenci', () {
    final computation = evaluateOeeEngine(
      reference(
        speedOriginal: 0.4,
        speedUnit: SpeedUnit.unitsPerSecond,
        idealCycleSeconds: 0.4,
      ),
    );

    expect(computation.outcome, isNull);
    expect(computation.issues, [
      const OeeEngineIssue(
        field: OeeEngineField.speed,
        code: OeeEngineIssueCode.unitMismatch,
      ),
    ]);
    expect(
      oeeEngineIssueMessage(computation.issues.single),
      'La unitat de la velocitat no coincideix amb el cicle canònic. No es fa cap conversió silenciosa.',
    );
  });

  test(
    'sense producció i amb temps operatiu, Q no aplica i el pastís tanca',
    () {
      final result = outcomeOf(
        reference(totalUnits: 0, goodUnits: 0, idealCycleSeconds: 1),
      );

      expect(result.oee, 0);
      expect(result.availability, closeTo(25200 / 28800, 1e-12));
      expect(result.performance, 0);
      expect(result.quality, isNull);
      expect(result.notes, contains(qualityNotApplicableMessage));
      expect(result.pie.allowed, isTrue);
      expect(
        [for (final slice in result.pie.slices) slice.seconds],
        [0, 3600, 25200, 0],
      );
    },
  );

  test('sense temps operatiu ni producció, R i Q no apliquen', () {
    final result = outcomeOf(
      reference(
        plannedMinutes: 480,
        downtimeMinutes: 480,
        totalUnits: 0,
        goodUnits: 0,
      ),
    );

    expect(result.availability, 0);
    expect(result.oee, 0);
    expect(result.performance, isNull);
    expect(result.quality, isNull);
    expect(result.notes, contains(performanceNotApplicableMessage));
    expect(result.notes, contains(qualityNotApplicableMessage));
    expect(result.pie.allowed, isTrue);
    expect(result.pie.slices[1].seconds, result.plannedSeconds);
    expect(result.pie.slices[0].seconds, 0);
    expect(result.pie.slices[2].seconds, 0);
    expect(result.pie.slices[3].seconds, 0);
  });

  test('producció amb temps operatiu zero no mostra un OEE', () {
    final computation = evaluateOeeEngine(
      reference(
        plannedMinutes: 10,
        downtimeMinutes: 10,
        totalUnits: 5,
        goodUnits: 4,
      ),
    );

    expect(computation.outcome, isNull);
    expect(
      computation.issues.single.code,
      OeeEngineIssueCode.inconsistentOperating,
    );
    expect(
      oeeEngineIssueMessage(computation.issues.single),
      'No hi pot haver producció amb temps operatiu zero.',
    );
    expect(
      engineFieldHasError(OeeEngineField.downtimeMinutes, computation.issues),
      isTrue,
    );
  });

  test('un rendiment real superior a 1 no es capa ni pinta el pastís', () {
    final result = outcomeOf(
      reference(
        plannedMinutes: 60,
        downtimeMinutes: 0,
        speedOriginal: 30,
        idealCycleSeconds: 30,
        totalUnits: 150,
        goodUnits: 150,
      ),
    );

    expect(result.performance, closeTo(1.25, 1e-12));
    expect(result.oee, closeTo(1.25, 1e-12));
    expect(formatOeeEnginePercent(result.performance!), '125 %');
    expect(result.performanceAboveIdeal, isTrue);
    expect(result.allowsDraft, isTrue);
    expect(result.allowsValidation, isFalse);
    expect(result.pie.allowed, isFalse);
    expect(result.pie.slices, isEmpty);
    expect(result.notes, contains(performanceAboveIdealMessage));
    expect(result.notes, contains(validationBlockedMessage));
    expect(result.notes, contains(pieNegativeMessage));
    expect(result.notes, isNot(contains(calculationNotStoredMessage)));
  });

  test('un residu numèric es normalitza només al pastís', () {
    final pie = decidePlannedTimePie(
      plannedSeconds: 28800,
      productiveSeconds: 22800,
      availabilitySeconds: 3600,
      performanceSeconds: -1e-8,
      qualitySeconds: 2400,
    );

    expect(pie.allowed, isTrue);
    expect(pie.normalizedResidue, isTrue);
    expect(pie.note, pieResidueMessage);
    expect(pie.slices[2].seconds, 0);
    expect(pie.slices.any((slice) => slice.seconds < 0), isFalse);
  });

  test('una porció negativa real no es presenta com un pastís vàlid', () {
    final pie = decidePlannedTimePie(
      plannedSeconds: 3600,
      productiveSeconds: 4500,
      availabilitySeconds: 0,
      performanceSeconds: -900,
      qualitySeconds: 0,
    );

    expect(pie.allowed, isFalse);
    expect(pie.slices, isEmpty);
    expect(pie.note, pieNegativeMessage);
  });

  test(
    'G superior a N, temps invàlids i comptatges fraccionaris no calculen',
    () {
      final good = evaluateOeeEngine(reference(totalUnits: 10, goodUnits: 11));
      expect(good.outcome, isNull);
      expect(good.issues.single.code, OeeEngineIssueCode.goodExceedsTotal);

      final planned = evaluateOeeEngine(
        reference(plannedMinutes: 0, downtimeMinutes: 0),
      );
      expect(planned.outcome, isNull);
      expect(
        planned.issues.map((issue) => issue.code),
        contains(OeeEngineIssueCode.plannedNotPositive),
      );

      final downtime = evaluateOeeEngine(
        reference(plannedMinutes: 30, downtimeMinutes: 31),
      );
      expect(downtime.outcome, isNull);
      expect(
        downtime.issues.single.code,
        OeeEngineIssueCode.downtimeExceedsPlanned,
      );

      final cycle = evaluateOeeEngine(
        reference(speedOriginal: 0, idealCycleSeconds: null),
      );
      expect(cycle.outcome, isNull);
      expect(cycle.issues.single.code, OeeEngineIssueCode.speedNotPositive);

      final rate = evaluateOeeEngine(
        reference(
          speedOriginal: -2,
          speedUnit: SpeedUnit.unitsPerSecond,
          idealCycleSeconds: null,
        ),
      );
      expect(rate.outcome, isNull);
      expect(rate.issues.single.code, OeeEngineIssueCode.speedNotPositive);

      final negative = evaluateOeeEngine(
        reference(totalUnits: -1, goodUnits: 0),
      );
      expect(negative.outcome, isNull);
      expect(negative.issues.single.code, OeeEngineIssueCode.totalNegative);

      final both = evaluateOeeEngine(
        reference(
          plannedMinutes: 0,
          downtimeMinutes: 5,
          idealCycleSeconds: null,
        ),
      );
      expect(both.outcome, isNull);
      expect(both.issues.map((issue) => issue.code), [
        OeeEngineIssueCode.plannedNotPositive,
        OeeEngineIssueCode.downtimeExceedsPlanned,
      ]);
    },
  );

  test('el text buit, ambigu, no finit i no enter identifica el camp', () {
    expect(parseOeeEngineDecimal('1.234').value, 1.234);
    expect(parseOeeEngineDecimal('1,5').value, 1.5);
    expect(parseOeeEngineDecimal(' 2.25 ').value, 2.25);
    expect(
      parseOeeEngineDecimal('1.234,56').issueCode,
      OeeEngineIssueCode.ambiguousThousands,
    );
    expect(
      parseOeeEngineDecimal('1,234.56').issueCode,
      OeeEngineIssueCode.ambiguousThousands,
    );
    expect(
      parseOeeEngineDecimal('1.234.567').issueCode,
      OeeEngineIssueCode.ambiguousThousands,
    );
    expect(
      parseOeeEngineDecimal('NaN').issueCode,
      OeeEngineIssueCode.notFinite,
    );
    expect(
      parseOeeEngineDecimal('Infinity').issueCode,
      OeeEngineIssueCode.notFinite,
    );
    expect(
      parseOeeEngineDecimal('1e2').issueCode,
      OeeEngineIssueCode.invalidNumber,
    );
    expect(
      parseOeeEngineInteger('10.0').issueCode,
      OeeEngineIssueCode.notInteger,
    );
    expect(
      parseOeeEngineInteger('10,5').issueCode,
      OeeEngineIssueCode.notInteger,
    );
    expect(parseOeeEngineInteger('24000').value, 24000);

    final reading = interpretOeeEngineText(
      planned: '',
      downtime: 'Infinity',
      speed: '1.234,56',
      speedUnit: SpeedUnit.secondsPerUnit,
      total: '10.5',
      good: '',
      canonicalCycle: null,
    );
    expect(reading.outcome, isNull);
    expect(reading.issues.map((issue) => issue.field), [
      OeeEngineField.plannedMinutes,
      OeeEngineField.downtimeMinutes,
      OeeEngineField.speed,
      OeeEngineField.totalUnits,
      OeeEngineField.goodUnits,
    ]);
    expect(reading.issues.map(oeeEngineIssueMessage), [
      'El temps planificat és obligatori.',
      'El temps de parades no és un nombre finit.',
      'La velocitat té separadors de milers ambigus.',
      'Les unitats totals han de ser un enter, sense decimals ni separadors de milers.',
      'Les unitats bones són obligatòries.',
    ]);
  });

  test('avaluar el motor no reescriu un registre ja capturat', () {
    final captured = OeeRecord(
      id: 'n50',
      productionDate: '2026-03-01',
      shift: 'Matí',
      lineId: 'n4',
      article: 'Iogurt natural',
      lot: null,
      plannedMinutes: 480,
      downtimeMinutes: 60,
      speedOriginal: 1,
      speedUnit: SpeedUnit.secondsPerUnit,
      idealCycleSeconds: 1,
      totalUnits: 24000,
      goodUnits: 22800,
      status: OeeRecordStatus.validated,
      formulaVersion: oeeFormulaVersion,
      capturedLineName: 'Línia iogurt',
      capturedPlantName: 'Planta Girona',
      createdAt: DateTime.utc(2026, 3, 2),
      updatedAt: DateTime.utc(2026, 3, 2),
    );
    evaluateOeeEngine(
      reference(
        plannedMinutes: 1,
        downtimeMinutes: 0,
        speedOriginal: 30,
        idealCycleSeconds: 30,
        totalUnits: 150,
        goodUnits: 150,
      ),
    );

    expect(captured.idealCycleSeconds, 1);
    expect(captured.capturedLineName, 'Línia iogurt');
    expect(captured.totalUnits, 24000);
    expect(captured.status, OeeRecordStatus.validated);
  });
}
