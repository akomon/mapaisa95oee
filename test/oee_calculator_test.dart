import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/oee_calculator.dart';

void main() {
  OeeInputs inputs({
    double plannedMinutes = 480,
    double downtimeMinutes = 60,
    double idealCycleSeconds = 60,
    double totalUnits = 400,
    double goodUnits = 380,
  }) {
    return OeeInputs(
      plannedMinutes: plannedMinutes,
      downtimeMinutes: downtimeMinutes,
      idealCycleSeconds: idealCycleSeconds,
      totalUnits: totalUnits,
      goodUnits: goodUnits,
    );
  }

  OeeResult resultOf(OeeInputs value) {
    final computation = calculateOee(value);
    expect(computation.issues, isEmpty);
    expect(computation.isValid, isTrue);
    return computation.result!;
  }

  test('torn estàndard: 79.2 % i pèrdua de disponibilitat', () {
    final result = resultOf(inputs());

    expect(result.availability, closeTo(420 / 480, 1e-12));
    expect(result.performance, closeTo(24000 / 25200, 1e-12));
    expect(result.quality, closeTo(0.95, 1e-12));
    expect(result.oee, closeTo(133 / 168, 1e-12));
    expect(formatOeePercent(result.availability), '87.5 %');
    expect(formatOeePercent(result.performance), '95.2 %');
    expect(formatOeePercent(result.quality), '95.0 %');
    expect(formatOeePercent(result.oee), '79.2 %');
    expect(result.mainLosses, [OeeFactor.availability]);
    expect(result.performanceAboveIdeal, isFalse);
    expect(
      mainLossMessage(result.mainLosses),
      'Pèrdua principal: Disponibilitat.',
    );
  });

  test('torn perfecte: els tres factors empaten al 100 %', () {
    final result = resultOf(
      inputs(
        plannedMinutes: 100,
        downtimeMinutes: 0,
        idealCycleSeconds: 60,
        totalUnits: 100,
        goodUnits: 100,
      ),
    );

    expect(formatOeePercent(result.availability), '100.0 %');
    expect(formatOeePercent(result.performance), '100.0 %');
    expect(formatOeePercent(result.quality), '100.0 %');
    expect(formatOeePercent(result.oee), '100.0 %');
    expect(result.mainLosses, OeeFactor.values);
    expect(result.performanceAboveIdeal, isFalse);
    expect(
      mainLossMessage(result.mainLosses),
      'Pèrdua principal: Disponibilitat, Rendiment i Qualitat.',
    );
  });

  test('cicle ideal massa curt: rendiment 125 % i avís', () {
    final result = resultOf(
      inputs(
        plannedMinutes: 60,
        downtimeMinutes: 0,
        idealCycleSeconds: 30,
        totalUnits: 150,
        goodUnits: 150,
      ),
    );

    expect(formatOeePercent(result.availability), '100.0 %');
    expect(formatOeePercent(result.performance), '125.0 %');
    expect(formatOeePercent(result.quality), '100.0 %');
    expect(formatOeePercent(result.oee), '125.0 %');
    expect(result.performanceAboveIdeal, isTrue);
    expect(result.mainLosses, [OeeFactor.availability, OeeFactor.quality]);
    expect(
      mainLossMessage(result.mainLosses),
      'Pèrdua principal: Disponibilitat i Qualitat.',
    );
  });

  test('cicle ideal zero: rendiment i OEE a 0 %', () {
    final result = resultOf(
      inputs(
        plannedMinutes: 60,
        downtimeMinutes: 0,
        idealCycleSeconds: 0,
        totalUnits: 10,
        goodUnits: 10,
      ),
    );

    expect(formatOeePercent(result.performance), '0.0 %');
    expect(formatOeePercent(result.oee), '0.0 %');
    expect(result.mainLosses, [OeeFactor.performance]);
    expect(result.performanceAboveIdeal, isFalse);
  });

  test('qualitat és la pèrdua principal quan és el factor més baix', () {
    final result = resultOf(
      inputs(
        plannedMinutes: 60,
        downtimeMinutes: 0,
        idealCycleSeconds: 60,
        totalUnits: 60,
        goodUnits: 30,
      ),
    );

    expect(formatOeePercent(result.availability), '100.0 %');
    expect(formatOeePercent(result.performance), '100.0 %');
    expect(formatOeePercent(result.quality), '50.0 %');
    expect(formatOeePercent(result.oee), '50.0 %');
    expect(result.mainLosses, [OeeFactor.quality]);
  });

  test('rendiment i qualitat empaten per sota de la disponibilitat', () {
    final result = resultOf(
      inputs(
        plannedMinutes: 100,
        downtimeMinutes: 0,
        idealCycleSeconds: 30,
        totalUnits: 100,
        goodUnits: 50,
      ),
    );

    expect(formatOeePercent(result.availability), '100.0 %');
    expect(formatOeePercent(result.performance), '50.0 %');
    expect(formatOeePercent(result.quality), '50.0 %');
    expect(result.mainLosses, [OeeFactor.performance, OeeFactor.quality]);
    expect(
      mainLossMessage(result.mainLosses),
      'Pèrdua principal: Rendiment i Qualitat.',
    );
  });

  test('un negatiu amaga la resta d\'incidències', () {
    final computation = calculateOee(
      inputs(plannedMinutes: -1, goodUnits: 999, downtimeMinutes: 9999),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.negativeValue]);
  });

  test('bones superiors a les totals', () {
    final computation = calculateOee(inputs(totalUnits: 10, goodUnits: 11));

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.goodExceedsTotal]);
  });

  test('parades superiors al temps planificat', () {
    final computation = calculateOee(
      inputs(plannedMinutes: 30, downtimeMinutes: 31),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.downtimeExceedsPlanned]);
  });

  test('planificat zero no afegeix temps operatiu zero', () {
    final computation = calculateOee(
      inputs(
        plannedMinutes: 0,
        downtimeMinutes: 0,
        idealCycleSeconds: 1,
        totalUnits: 10,
        goodUnits: 10,
      ),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.plannedTimeZero]);
  });

  test('planificat i totals a zero reporten les dues divisions', () {
    final computation = calculateOee(
      inputs(
        plannedMinutes: 0,
        downtimeMinutes: 0,
        idealCycleSeconds: 0,
        totalUnits: 0,
        goodUnits: 0,
      ),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [
      OeeIssueCode.plannedTimeZero,
      OeeIssueCode.totalUnitsZero,
    ]);
  });

  test('temps operatiu zero amb planificat positiu', () {
    final computation = calculateOee(
      inputs(plannedMinutes: 45, downtimeMinutes: 45),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.operatingTimeZero]);
  });

  test('totals zero i bones positives acumulen les dues incidències', () {
    final computation = calculateOee(
      inputs(
        plannedMinutes: 10,
        downtimeMinutes: 0,
        idealCycleSeconds: 1,
        totalUnits: 0,
        goodUnits: 5,
      ),
    );

    expect(computation.result, isNull);
    expect(computation.issues, [
      OeeIssueCode.goodExceedsTotal,
      OeeIssueCode.totalUnitsZero,
    ]);
  });

  test('valors no finits es rebutgen', () {
    final computation = calculateOee(inputs(plannedMinutes: double.nan));

    expect(computation.result, isNull);
    expect(computation.issues, [OeeIssueCode.invalidNumber]);
  });

  test('parseig de decimals buits, coma i text invàlid', () {
    expect(parseOeeDecimal(''), isNull);
    expect(parseOeeDecimal('   '), isNull);
    expect(parseOeeDecimal('1,5'), 1.5);
    expect(parseOeeDecimal(' 2.25 '), 2.25);
    expect(parseOeeDecimal('-3'), -3);
    expect(parseOeeDecimal('+4'), 4);
    expect(() => parseOeeDecimal('abc'), throwsFormatException);
    expect(() => parseOeeDecimal('1.2.3'), throwsFormatException);
    expect(() => parseOeeDecimal('1e2'), throwsFormatException);
    expect(() => parseOeeDecimal('-'), throwsFormatException);
  });

  test('format amb 1 decimal, inclòs l\'empat .5', () {
    expect(formatOeePercent(0), '0.0 %');
    expect(formatOeePercent(1), '100.0 %');
    expect(formatOeePercent(1.25), '125.0 %');
    expect(formatOeePercent(0.8755), '87.6 %');
  });

  test('missatges de cada incidència', () {
    expect(OeeIssueCode.values.map(oeeIssueMessage).toList(), [
      'Introdueix un nombre vàlid.',
      'Els valors no poden ser negatius.',
      'Les unitats bones no poden superar les unitats totals.',
      'El temps de parades no pot superar el temps planificat.',
      'El temps planificat ha de ser més gran que zero.',
      'El temps operatiu és zero; no es pot calcular el rendiment.',
      'Les unitats totals han de ser més grans que zero.',
    ]);
    expect(() => mainLossMessage(const []), throwsArgumentError);
  });
}
