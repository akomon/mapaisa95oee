// Històric OEE de la secció 16. Sense Flutter.
// Contracte: specs/redesign/phase-e.md

import 'oee_engine.dart';
import 'workspace_model.dart';

const String oeeNoRecordsMessage = 'Encara no hi ha registres OEE.';

const String oeeNoFilterMatchMessage = 'Cap registre amb aquests filtres.';

const String oeeDateOrderMessage =
    'La data inicial és posterior a la data final.';

const String oeeInvalidDateMessage =
    'La data de producció ha de ser AAAA-MM-DD.';

const String oeeEmptyLotFilterMessage = 'Escriu el lot per filtrar.';

const String oeeArticleRequiredMessage = 'L\'article és obligatori.';

const String oeeShiftRequiredMessage = 'El torn és obligatori.';

const String oeeMissingPlantMessage =
    'Aquesta línia no té una planta. No es desa el registre.';

const String oeeImmutableMessage =
    'Un registre validat no es modifica. Corregir-lo crea una revisió.';

const String oeeNotValidatableMessage = 'No es pot validar aquest resultat.';

const String oeeMissingRecordMessage = 'No s\'ha trobat el registre.';

const String oeeCorrectValidatedOnlyMessage =
    'Només es corregeix un registre validat.';

const String oeeLineRetiredNote =
    'La línia ja no és a l\'inventari. Es conserva el nom capturat.';

const String oeeLineRenamedNote =
    'El nom actual de la línia és diferent. L\'etiqueta històrica no canvia.';

const String oeeNoAggregationMessage =
    'Indicadors per registre. Sense mitjana ni agregació.';

enum OeeHistoryIssueCode {
  emptyArticle,
  emptyShift,
  invalidDate,
  missingPlant,
  immutable,
  notValidatable,
  missingRecord,
  correctValidatedOnly,
  engine,
}

class OeeHistoryIssue {
  const OeeHistoryIssue(this.code, this.message);

  final OeeHistoryIssueCode code;
  final String message;
}

class OeeHistoryMutation {
  const OeeHistoryMutation.success(this.workspace, {required this.recordId})
    : issues = const [];

  const OeeHistoryMutation.failure(this.issues) : workspace = null, recordId = null;

  final Workspace? workspace;
  final String? recordId;
  final List<OeeHistoryIssue> issues;

  bool get isValid => workspace != null && issues.isEmpty;
}

enum OeeRecordScope { validated, drafts, all }

enum OeeLotMode { any, empty, exact }

class OeeHistoryQuery {
  const OeeHistoryQuery({
    this.from = '',
    this.to = '',
    this.shift = '',
    this.lineId,
    this.article = '',
    this.lotMode = OeeLotMode.any,
    this.lot = '',
    this.scope = OeeRecordScope.validated,
  });

  final String from;
  final String to;
  final String shift;
  final String? lineId;
  final String article;
  final OeeLotMode lotMode;
  final String lot;
  final OeeRecordScope scope;
}

class OeeLineOption {
  const OeeLineOption({required this.lineId, required this.label});

  /// Null és «Totes les línies».
  final String? lineId;
  final String label;
}

class OeeHistoryView {
  const OeeHistoryView({
    required this.records,
    required this.messages,
    required this.blocked,
  });

  final List<OeeRecord> records;
  final List<String> messages;
  final bool blocked;
}

bool isOeeProductionDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return false;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

Asset? plantAncestor(Workspace workspace, Asset line) {
  var current = line;
  final seen = <String>{};
  while (current.kind != AssetKind.plant) {
    if (!seen.add(current.id)) {
      return null;
    }
    final parent = findAsset(workspace, current.parentId);
    if (parent == null) {
      return null;
    }
    current = parent;
  }
  return current;
}

OeeRecord? findOeeRecord(Workspace workspace, String id) {
  for (final record in workspace.oeeRecords) {
    if (record.id == id) {
      return record;
    }
  }
  return null;
}

OeeEngineComputation computationForRecord(OeeRecord record) {
  return evaluateOeeEngine(
    OeeEngineInputs(
      plannedMinutes: record.plannedMinutes,
      downtimeMinutes: record.downtimeMinutes,
      speedOriginal: record.speedOriginal,
      speedUnit: record.speedUnit,
      totalUnits: record.totalUnits,
      goodUnits: record.goodUnits,
      idealCycleSeconds: record.idealCycleSeconds,
    ),
  );
}

String oeeRecordIndicatorLabel(OeeRecord record) {
  final outcome = computationForRecord(record).outcome;
  if (outcome == null) {
    return 'Sense indicador';
  }
  return 'OEE: ${formatOeeEnginePercent(outcome.oee)}';
}

String? lineContextNote(Workspace workspace, OeeRecord record) {
  final asset = findAsset(workspace, record.lineId);
  if (asset == null || asset.kind != AssetKind.line) {
    return oeeLineRetiredNote;
  }
  if (asset.name != record.capturedLineName) {
    return oeeLineRenamedNote;
  }
  return null;
}

Set<String> replacedValidatedIds(Workspace workspace) {
  final validated = {
    for (final record in workspace.oeeRecords)
      if (record.status == OeeRecordStatus.validated) record.id,
  };
  return {
    for (final record in workspace.oeeRecords)
      if (record.status == OeeRecordStatus.validated &&
          record.replacesId != null &&
          validated.contains(record.replacesId))
        record.replacesId!,
  };
}

List<OeeLineOption> oeeLineOptions(Workspace workspace) {
  final live = [
    for (final asset in workspace.assets)
      if (asset.kind == AssetKind.line) asset,
  ];
  final liveIds = {for (final line in live) line.id};
  final retired = <String, String>{};
  for (final record in workspace.oeeRecords) {
    if (!liveIds.contains(record.lineId)) {
      retired.putIfAbsent(record.lineId, () => record.capturedLineName);
    }
  }
  final retiredIds = retired.keys.toList()..sort();
  return [
    const OeeLineOption(lineId: null, label: 'Totes les línies'),
    for (final line in live) OeeLineOption(lineId: line.id, label: line.name),
    for (final id in retiredIds)
      OeeLineOption(lineId: id, label: '${retired[id]} · línia retirada'),
  ];
}

OeeHistoryView queryOeeHistory(Workspace workspace, OeeHistoryQuery query) {
  final messages = <String>[];
  final from = query.from.trim();
  final to = query.to.trim();
  if (from.isNotEmpty && !isOeeProductionDate(from)) {
    messages.add(oeeInvalidDateMessage);
  }
  if (to.isNotEmpty && !isOeeProductionDate(to)) {
    messages.add(oeeInvalidDateMessage);
  }
  if (query.lotMode == OeeLotMode.exact && query.lot.trim().isEmpty) {
    messages.add(oeeEmptyLotFilterMessage);
  }
  if (messages.isNotEmpty) {
    return OeeHistoryView(records: const [], messages: messages, blocked: true);
  }
  if (from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0) {
    return const OeeHistoryView(
      records: [],
      messages: [oeeDateOrderMessage],
      blocked: true,
    );
  }

  final hidden = replacedValidatedIds(workspace);
  final shift = query.shift.trim().toLowerCase();
  final article = query.article.trim().toLowerCase();
  final lot = query.lot.trim().toLowerCase();
  final matched = [
    for (final record in workspace.oeeRecords)
      if (_matches(
        record,
        query: query,
        hidden: hidden,
        from: from,
        to: to,
        shift: shift,
        article: article,
        lot: lot,
      ))
        record,
  ]..sort((left, right) {
    final byDate = right.productionDate.compareTo(left.productionDate);
    if (byDate != 0) {
      return byDate;
    }
    return right.id.compareTo(left.id);
  });
  if (matched.isEmpty) {
    return OeeHistoryView(
      records: const [],
      messages: [
        workspace.oeeRecords.isEmpty
            ? oeeNoRecordsMessage
            : oeeNoFilterMatchMessage,
      ],
      blocked: false,
    );
  }
  return OeeHistoryView(records: matched, messages: const [], blocked: false);
}

bool _matches(
  OeeRecord record, {
  required OeeHistoryQuery query,
  required Set<String> hidden,
  required String from,
  required String to,
  required String shift,
  required String article,
  required String lot,
}) {
  if (hidden.contains(record.id)) {
    return false;
  }
  switch (query.scope) {
    case OeeRecordScope.validated:
      if (record.status != OeeRecordStatus.validated) {
        return false;
      }
    case OeeRecordScope.drafts:
      if (record.status != OeeRecordStatus.draft) {
        return false;
      }
    case OeeRecordScope.all:
      break;
  }
  if (from.isNotEmpty && record.productionDate.compareTo(from) < 0) {
    return false;
  }
  if (to.isNotEmpty && record.productionDate.compareTo(to) > 0) {
    return false;
  }
  if (shift.isNotEmpty && record.shift.toLowerCase() != shift) {
    return false;
  }
  if (query.lineId != null && record.lineId != query.lineId) {
    return false;
  }
  if (article.isNotEmpty && !record.article.toLowerCase().contains(article)) {
    return false;
  }
  switch (query.lotMode) {
    case OeeLotMode.any:
      break;
    case OeeLotMode.empty:
      if (record.lot != null) {
        return false;
      }
    case OeeLotMode.exact:
      if ((record.lot ?? '').toLowerCase() != lot) {
        return false;
      }
  }
  return true;
}

OeeHistoryMutation saveOeeRecord(
  Workspace workspace, {
  required DateTime now,
  required String lineId,
  required String productionDate,
  required String shift,
  required String article,
  required String lot,
  required OeeEngineInputs inputs,
  required OeeRecordStatus status,
  String? recordId,
  String? replacesId,
}) {
  final issues = <OeeHistoryIssue>[];
  final articleText = article.trim();
  final shiftText = shift.trim();
  final dateText = productionDate.trim();
  if (articleText.isEmpty) {
    issues.add(
      const OeeHistoryIssue(
        OeeHistoryIssueCode.emptyArticle,
        oeeArticleRequiredMessage,
      ),
    );
  }
  if (shiftText.isEmpty) {
    issues.add(
      const OeeHistoryIssue(
        OeeHistoryIssueCode.emptyShift,
        oeeShiftRequiredMessage,
      ),
    );
  }
  if (!isOeeProductionDate(dateText)) {
    issues.add(
      const OeeHistoryIssue(
        OeeHistoryIssueCode.invalidDate,
        oeeInvalidDateMessage,
      ),
    );
  }
  final line = findAsset(workspace, lineId);
  final plant = line != null && line.kind == AssetKind.line
      ? plantAncestor(workspace, line)
      : null;
  if (line == null || line.kind != AssetKind.line || plant == null) {
    issues.add(
      const OeeHistoryIssue(
        OeeHistoryIssueCode.missingPlant,
        oeeMissingPlantMessage,
      ),
    );
  }

  OeeRecord? current;
  if (recordId != null) {
    current = findOeeRecord(workspace, recordId);
    if (current == null) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.missingRecord,
          oeeMissingRecordMessage,
        ),
      );
    } else if (current.status != OeeRecordStatus.draft) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.immutable,
          oeeImmutableMessage,
        ),
      );
    } else if (current.lineId != lineId) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.missingRecord,
          'Aquest esborrany és d\'una altra línia.',
        ),
      );
    }
  }

  OeeRecord? replaced;
  final link = recordId == null ? replacesId : current?.replacesId;
  if (recordId == null && replacesId != null) {
    replaced = findOeeRecord(workspace, replacesId);
    if (replaced == null) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.missingRecord,
          oeeMissingRecordMessage,
        ),
      );
    } else if (replaced.status != OeeRecordStatus.validated) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.correctValidatedOnly,
          oeeCorrectValidatedOnlyMessage,
        ),
      );
    }
  }

  final computed = evaluateOeeEngine(inputs);
  if (computed.outcome == null) {
    if (computed.issues.isEmpty) {
      issues.add(
        const OeeHistoryIssue(
          OeeHistoryIssueCode.engine,
          oeeNotValidatableMessage,
        ),
      );
    }
    for (final issue in computed.issues) {
      issues.add(
        OeeHistoryIssue(
          OeeHistoryIssueCode.engine,
          oeeEngineIssueMessage(issue),
        ),
      );
    }
  } else if (status == OeeRecordStatus.validated &&
      !computed.outcome!.allowsValidation) {
    issues.add(
      const OeeHistoryIssue(
        OeeHistoryIssueCode.notValidatable,
        oeeNotValidatableMessage,
      ),
    );
  }
  if (issues.isNotEmpty || computed.outcome == null || line == null || plant == null) {
    return OeeHistoryMutation.failure(issues);
  }

  final outcome = computed.outcome!;
  final lotText = lot.trim();
  final stamp = now.toUtc();
  final id = current?.id ?? allocateWorkspaceId(workspace);
  final record = OeeRecord(
    id: id,
    productionDate: dateText,
    shift: shiftText,
    lineId: line.id,
    article: articleText,
    lot: lotText.isEmpty ? null : lotText,
    plannedMinutes: inputs.plannedMinutes,
    downtimeMinutes: inputs.downtimeMinutes,
    speedOriginal: outcome.speedOriginal,
    speedUnit: outcome.speedUnit,
    idealCycleSeconds: outcome.idealCycleSeconds,
    totalUnits: outcome.totalUnits,
    goodUnits: outcome.goodUnits,
    status: status,
    formulaVersion: outcome.formulaVersion,
    capturedLineName: current?.capturedLineName ?? line.name,
    capturedPlantName: current?.capturedPlantName ?? plant.name,
    createdAt: current?.createdAt ?? stamp,
    updatedAt: stamp,
    replacesId: link,
  );
  final records = [
    for (final item in workspace.oeeRecords)
      if (item.id != id) item,
    record,
  ];
  return OeeHistoryMutation.success(
    workspace.copyWith(
      nextIdCounter: current == null
          ? workspaceCounterAfter(id, workspace.nextIdCounter)
          : workspace.nextIdCounter,
      oeeRecords: records,
    ),
    recordId: id,
  );
}
