import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/oee_engine.dart';
import 'package:mapaisa95oee/oee_history.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 3, 2, 8);
  final later = DateTime.utc(2026, 3, 3, 8);

  const reference = OeeEngineInputs(
    plannedMinutes: 480,
    downtimeMinutes: 60,
    speedOriginal: 1,
    speedUnit: SpeedUnit.secondsPerUnit,
    totalUnits: 24000,
    goodUnits: 22800,
    idealCycleSeconds: 1,
  );

  const excessive = OeeEngineInputs(
    plannedMinutes: 1,
    downtimeMinutes: 0,
    speedOriginal: 1,
    speedUnit: SpeedUnit.secondsPerUnit,
    totalUnits: 100,
    goodUnits: 100,
    idealCycleSeconds: 1,
  );

  OeeHistoryMutation save(
    Workspace workspace, {
    OeeEngineInputs inputs = reference,
    OeeRecordStatus status = OeeRecordStatus.validated,
    String article = 'Iogurt natural',
    String shift = 'Matí',
    String lot = '',
    String date = '2026-03-01',
    String lineId = 'n4',
    String? recordId,
    String? replacesId,
    DateTime? at,
  }) {
    return saveOeeRecord(
      workspace,
      now: at ?? now,
      lineId: lineId,
      productionDate: date,
      shift: shift,
      article: article,
      lot: lot,
      inputs: inputs,
      status: status,
      recordId: recordId,
      replacesId: replacesId,
    );
  }

  test('desa el registre amb c congelat i lot buit', () {
    final saved = save(foodIndustryExample());
    expect(saved.isValid, isTrue);
    final record = saved.workspace!.oeeRecords.single;
    expect(record.id, 'n21');
    expect(record.lot, isNull);
    expect(record.capturedLineName, 'Línia iogurt');
    expect(record.capturedPlantName, 'Planta Girona');
    expect(record.idealCycleSeconds, 1);
    expect(record.speedOriginal, 1);
    expect(record.formulaVersion, 'oee.v1');
    expect(record.status, OeeRecordStatus.validated);
    expect(record.replacesId, isNull);
    expect(record.productionDate, '2026-03-01');
    expect(oeeRecordIndicatorLabel(record), 'OEE: 79.166667 %');
    expect(computationForRecord(record).outcome!.pie.allowed, isTrue);

    final renamed = updateAsset(
      saved.workspace!,
      id: 'n4',
      name: 'Línia nova',
      now: later,
    );
    expect(oeeRecordsJson(renamed.workspace!), oeeRecordsJson(saved.workspace!));
    expect(lineContextNote(renamed.workspace!, record), oeeLineRenamedNote);

    final otherSpeed = OeeEngineInputs(
      plannedMinutes: 480,
      downtimeMinutes: 60,
      speedOriginal: 2,
      speedUnit: SpeedUnit.secondsPerUnit,
      totalUnits: 1000,
      goodUnits: 900,
      idealCycleSeconds: 2,
    );
    final second = save(
      renamed.workspace!,
      inputs: otherSpeed,
      article: 'Formatge',
      at: later,
    );
    expect(second.workspace!.oeeRecords, hasLength(2));
    expect(
      findOeeRecord(second.workspace!, record.id)!.idealCycleSeconds,
      1,
    );
    expect(
      findOeeRecord(second.workspace!, record.id)!.capturedLineName,
      'Línia iogurt',
    );
  });

  test('rebutja buits, data invàlida, planta absent i rendiment excessiu', () {
    final base = foodIndustryExample();
    expect(save(base, article: '  ').workspace, isNull);
    expect(save(base, shift: '').issues.first.message, oeeShiftRequiredMessage);
    expect(
      save(base, date: '2026-13-40').issues.map((issue) => issue.message),
      contains(oeeInvalidDateMessage),
    );
    expect(save(base, lineId: 'n1').issues.first.message, oeeMissingPlantMessage);

    final draft = save(base, inputs: excessive, status: OeeRecordStatus.draft);
    expect(draft.isValid, isTrue);
    expect(
      computationForRecord(draft.workspace!.oeeRecords.single).outcome!.pie.allowed,
      isFalse,
    );
    final blocked = save(
      draft.workspace!,
      inputs: excessive,
      status: OeeRecordStatus.validated,
      recordId: draft.recordId,
    );
    expect(blocked.workspace, isNull);
    expect(blocked.issues.single.message, oeeNotValidatableMessage);
    expect(draft.workspace!.oeeRecords.single.status, OeeRecordStatus.draft);
  });

  test('el validat és immutable i la correcció el conserva', () {
    final first = save(foodIndustryExample());
    final originalJson = oeeRecordsJson(first.workspace!);
    final edited = save(
      first.workspace!,
      recordId: first.recordId,
      article: 'Canvi',
      status: OeeRecordStatus.draft,
    );
    expect(edited.workspace, isNull);
    expect(edited.issues.single.message, oeeImmutableMessage);

    const corrected = OeeEngineInputs(
      plannedMinutes: 480,
      downtimeMinutes: 60,
      speedOriginal: 1,
      speedUnit: SpeedUnit.secondsPerUnit,
      totalUnits: 24000,
      goodUnits: 22000,
      idealCycleSeconds: 1,
    );
    final revision = save(
      first.workspace!,
      replacesId: first.recordId,
      article: 'Iogurt corregit',
      inputs: corrected,
      at: later,
    );
    expect(revision.isValid, isTrue);
    expect(revision.workspace!.oeeRecords, hasLength(2));
    expect(oeeRecordsJson(first.workspace!), originalJson);
    final kept = findOeeRecord(revision.workspace!, first.recordId!)!;
    expect(kept.article, 'Iogurt natural');
    expect(kept.idealCycleSeconds, 1);
    expect(kept.replacesId, isNull);
    final view = queryOeeHistory(
      revision.workspace!,
      const OeeHistoryQuery(lineId: 'n4'),
    );
    expect(view.records.single.id, revision.recordId);
    expect(view.records.single.replacesId, first.recordId);
    expect(view.records.single.article, 'Iogurt corregit');
    expect(
      replacedValidatedIds(revision.workspace!),
      {first.recordId},
    );

    final draftRevision = save(
      first.workspace!,
      replacesId: first.recordId,
      status: OeeRecordStatus.draft,
      article: 'Encara no',
    );
    final validatedView = queryOeeHistory(
      draftRevision.workspace!,
      const OeeHistoryQuery(lineId: 'n4'),
    );
    expect(validatedView.records.single.id, first.recordId);
  });

  test('actualitza un esborrany al mateix id i el valida', () {
    final draft = save(
      foodIndustryExample(),
      status: OeeRecordStatus.draft,
      article: 'Esborrany',
    );
    final validated = save(
      draft.workspace!,
      recordId: draft.recordId,
      article: 'Ja vàlid',
      status: OeeRecordStatus.validated,
      at: later,
    );
    final record = validated.workspace!.oeeRecords.single;
    expect(record.id, draft.recordId);
    expect(record.status, OeeRecordStatus.validated);
    expect(record.article, 'Ja vàlid');
    expect(record.createdAt, now);
    expect(record.updatedAt, later);
    expect(record.capturedLineName, 'Línia iogurt');
  });

  test('filtra dates, torn, article, lot i estat', () {
    final records = [
      _record(id: 'n30', date: '2026-03-01', shift: 'Matí', article: 'Iogurt natural'),
      _record(
        id: 'n31',
        date: '2026-03-02',
        shift: 'Nit',
        article: 'Formatge',
        lot: 'L1',
      ),
      _record(
        id: 'n32',
        date: '2026-03-03',
        shift: 'Matí',
        article: 'Llet',
        lot: 'L10',
        status: OeeRecordStatus.draft,
      ),
      _record(id: 'n33', date: '2026-03-02', shift: 'matí', article: 'Iogurt batut', lineId: 'n7'),
    ];
    final workspace = foodIndustryExample().copyWith(oeeRecords: records);

    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(from: '2026-03-02', to: '2026-03-02', scope: OeeRecordScope.all),
      ).records.map((record) => record.id),
      ['n33', 'n31'],
    );
    final crossed = queryOeeHistory(
      workspace,
      const OeeHistoryQuery(from: '2026-03-03', to: '2026-03-01'),
    );
    expect(crossed.blocked, isTrue);
    expect(crossed.messages, [oeeDateOrderMessage]);
    final invalid = queryOeeHistory(
      workspace,
      const OeeHistoryQuery(from: '03/03/2026'),
    );
    expect(invalid.blocked, isTrue);
    expect(invalid.messages, [oeeInvalidDateMessage]);

    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(shift: ' matí ', scope: OeeRecordScope.all),
      ).records.map((record) => record.id),
      ['n32', 'n33', 'n30'],
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(shift: 'Mat', scope: OeeRecordScope.all),
      ).messages,
      [oeeNoFilterMatchMessage],
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(article: 'iogurt', scope: OeeRecordScope.all),
      ).records.map((record) => record.id),
      ['n33', 'n30'],
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(lotMode: OeeLotMode.empty, scope: OeeRecordScope.all),
      ).records.map((record) => record.id),
      ['n33', 'n30'],
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(lotMode: OeeLotMode.exact, lot: 'l1', scope: OeeRecordScope.all),
      ).records.single.id,
      'n31',
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(lotMode: OeeLotMode.exact, lot: ' '),
      ).messages,
      [oeeEmptyLotFilterMessage],
    );
    expect(
      queryOeeHistory(workspace, const OeeHistoryQuery()).records.map((record) => record.id),
      ['n33', 'n31', 'n30'],
    );
    expect(
      queryOeeHistory(
        workspace,
        const OeeHistoryQuery(scope: OeeRecordScope.drafts),
      ).records.single.id,
      'n32',
    );
    expect(
      queryOeeHistory(foodIndustryExample(), const OeeHistoryQuery()).messages,
      [oeeNoRecordsMessage],
    );
  });

  test('una línia eliminada es conserva i es filtra', () {
    final saved = save(foodIndustryExample(), lot: '  ');
    expect(saved.workspace!.oeeRecords.single.lot, isNull);
    final removed = deleteEntity(saved.workspace!, id: 'n4', confirm: true);
    expect(findAsset(removed.workspace!, 'n4'), isNull);
    final record = removed.workspace!.oeeRecords.single;
    expect(record.capturedLineName, 'Línia iogurt');
    expect(record.idealCycleSeconds, 1);
    expect(lineContextNote(removed.workspace!, record), oeeLineRetiredNote);
    final view = queryOeeHistory(
      removed.workspace!,
      const OeeHistoryQuery(lineId: 'n4'),
    );
    expect(view.records.single.id, record.id);
    expect(
      oeeLineOptions(removed.workspace!).map((option) => option.label),
      contains('Línia iogurt · línia retirada'),
    );
  });

  test('la còpia, la recàrrega i la restauració no muten l\'OEE', () async {
    final base = foodIndustryExample().copyWith(legacyRaw: 'cru');
    final saved = save(base);
    expect(saved.workspace!.legacyRaw, 'cru');
    final roundtrip = workspaceFromJson(workspaceToJson(saved.workspace!));
    expect(roundtrip.isValid, isTrue);
    expect(oeeRecordsJson(roundtrip.workspace!), oeeRecordsJson(saved.workspace!));
    expect(roundtrip.workspace!.oeeRecords.single.replacesId, isNull);
    expect(workspaceToJson(saved.workspace!), isNot(contains('replacesId')));

    final revision = save(
      saved.workspace!,
      replacesId: saved.recordId,
      article: 'Revisió',
      at: later,
    );
    final withLink = workspaceFromJson(workspaceToJson(revision.workspace!));
    expect(withLink.workspace!.oeeRecords.last.replacesId, saved.recordId);

    final broken = workspaceToJson(revision.workspace!).replaceFirst(
      '"replacesId": "${saved.recordId}"',
      '"replacesId": "n999"',
    );
    expect(
      workspaceFromJson(broken).issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.orphanReference),
    );
    final cycle = workspaceToJson(saved.workspace!).replaceFirst(
      '"formulaVersion": "oee.v1"',
      '"formulaVersion": "oee.v1", "replacesId": "n21"',
    );
    expect(
      workspaceFromJson(cycle).issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.cycle),
    );

    final database = MemoryWorkspaceDatabase();
    final repo = WorkspaceRepository(
      database: database,
      readLegacy: () async => 'legacy-key',
      now: () => now,
    );
    await repo.open();
    await repo.loadExample(confirm: true);
    final stored = save(repo.workspace.copyWith(legacyRaw: 'cru'));
    await repo.saveWorkspace(stored.workspace!);
    final again = WorkspaceRepository(
      database: database,
      readLegacy: () async => 'legacy-key',
      now: () => later,
    );
    await again.open();
    expect(again.workspace.oeeRecords.single.article, 'Iogurt natural');
    expect(again.workspace.oeeRecords.single.idealCycleSeconds, 1);
    expect(again.workspace.legacyRaw, 'cru');

    final snap = createSnapshot(
      again.workspace,
      schemaId: 'n20',
      note: 'abans',
      now: later,
    );
    final extra = save(
      snap.workspace!,
      article: 'Segon',
      date: '2026-03-04',
      at: later,
    );
    final before = oeeRecordsJson(extra.workspace!);
    final restored = restoreSnapshot(
      extra.workspace!,
      versionId: snap.workspace!.versions.last.id,
      note: 'torna',
      now: later,
    );
    expect(oeeRecordsJson(restored.workspace!), before);
    expect(restored.workspace!.versions, hasLength(2));
  });
}

OeeRecord _record({
  required String id,
  required String date,
  required String shift,
  required String article,
  String? lot,
  String lineId = 'n4',
  OeeRecordStatus status = OeeRecordStatus.validated,
}) {
  final stamp = DateTime.utc(2026, 3, 2);
  return OeeRecord(
    id: id,
    productionDate: date,
    shift: shift,
    lineId: lineId,
    article: article,
    lot: lot,
    plannedMinutes: 480,
    downtimeMinutes: 60,
    speedOriginal: 1,
    speedUnit: SpeedUnit.secondsPerUnit,
    idealCycleSeconds: 1,
    totalUnits: 24000,
    goodUnits: 22800,
    status: status,
    formulaVersion: 'oee.v1',
    capturedLineName: lineId == 'n4' ? 'Línia iogurt' : 'Línia formatge',
    capturedPlantName: 'Planta Girona',
    createdAt: stamp,
    updatedAt: stamp,
  );
}
