import 'package:flutter/material.dart';

import 'oee_engine.dart';
import 'oee_engine_panel.dart';
import 'oee_history.dart';
import 'workspace_model.dart';
import 'workspace_repository.dart';
import 'workspace_theme.dart';

const Key oeeCalculationModeKey = Key('oeeCalculationMode');
const Key oeeHistoryModeKey = Key('oeeHistoryMode');
const Key oeeDateKey = Key('oeeProductionDate');
const Key oeeShiftKey = Key('oeeShift');
const Key oeeArticleKey = Key('oeeArticle');
const Key oeeLotKey = Key('oeeLot');
const Key oeeCancelEditKey = Key('oeeCancelEdit');
const Key oeeNewRecordKey = Key('oeeNewRecord');
const Key oeeFilterFromKey = Key('oeeFilterFrom');
const Key oeeFilterToKey = Key('oeeFilterTo');
const Key oeeFilterShiftKey = Key('oeeFilterShift');
const Key oeeFilterArticleKey = Key('oeeFilterArticle');
const Key oeeFilterLotKey = Key('oeeFilterLot');
const Key oeeLotAnyKey = Key('oeeLotAny');
const Key oeeLotEmptyKey = Key('oeeLotEmpty');
const Key oeeLotExactKey = Key('oeeLotExact');
const Key oeeScopeValidatedKey = Key('oeeScopeValidated');
const Key oeeScopeDraftKey = Key('oeeScopeDraft');
const Key oeeScopeAllKey = Key('oeeScopeAll');
const Key oeeLineFilterKey = Key('oeeLineFilter');
const Key oeeCloseHistoryKey = Key('oeeCloseHistory');
const Key oeeCloseRecordKey = Key('oeeCloseRecord');
const Key oeePreviousRevisionKey = Key('oeePreviousRevision');
const Key oeeCorrectKey = Key('oeeCorrect');

Key oeeOpenRecordKey(String id) => Key('oeeOpen-$id');

class OeeLineWorkbench extends StatefulWidget {
  const OeeLineWorkbench({
    super.key,
    required this.repository,
    required this.line,
    this.initialHistory = false,
    this.pending,
    this.onHistoryChanged,
  });

  final WorkspaceRepository repository;
  final Asset line;
  final bool initialHistory;
  final OeeRecord? pending;
  final ValueChanged<bool>? onHistoryChanged;

  @override
  State<OeeLineWorkbench> createState() => _OeeLineWorkbenchState();
}

class _OeeLineWorkbenchState extends State<OeeLineWorkbench> {
  final _date = TextEditingController();
  final _shift = TextEditingController();
  final _article = TextEditingController();
  final _lot = TextEditingController();
  final _articleFocus = FocusNode();
  final _cancelFocus = FocusNode();

  var _history = false;
  var _seedToken = 0;
  OeeRecord? _seed;
  String? _editingId;
  String? _replacesId;
  String? _openId;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final pending = widget.pending;
    if (pending != null && pending.lineId == widget.line.id) {
      _applyRecord(pending);
      _history = false;
    } else {
      _history = widget.initialHistory;
    }
    widget.repository.addListener(_onRepo);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepo);
    _date.dispose();
    _shift.dispose();
    _article.dispose();
    _lot.dispose();
    _articleFocus.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  void _onRepo() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyRecord(OeeRecord record) {
    final correcting = record.status == OeeRecordStatus.validated;
    _editingId = correcting ? null : record.id;
    _replacesId = correcting ? record.id : record.replacesId;
    _seed = record;
    _seedToken += 1;
    _date.text = record.productionDate;
    _shift.text = record.shift;
    _article.text = record.article;
    _lot.text = record.lot ?? '';
    _formError = null;
    _openId = null;
    _history = false;
  }

  void _clearEditor() {
    _editingId = null;
    _replacesId = null;
    _seed = null;
    _seedToken += 1;
    _date.clear();
    _shift.clear();
    _article.clear();
    _lot.clear();
    _formError = null;
    _openId = null;
    _history = false;
  }

  Future<void> _save(OeeEngineInputs inputs, OeeRecordStatus status) async {
    final mutation = saveOeeRecord(
      widget.repository.workspace,
      now: widget.repository.now,
      lineId: widget.line.id,
      productionDate: _date.text,
      shift: _shift.text,
      article: _article.text,
      lot: _lot.text,
      inputs: inputs,
      status: status,
      recordId: _editingId,
      replacesId: _replacesId,
    );
    if (!mutation.isValid || mutation.workspace == null) {
      setState(() {
        _formError = mutation.issues.map((issue) => issue.message).join('\n');
      });
      return;
    }
    await widget.repository.saveWorkspace(mutation.workspace!);
    if (!mounted) {
      return;
    }
    setState(() {
      if (widget.repository.status == SaveStatus.saved) {
        _formError = null;
        _history = true;
        _openId = mutation.recordId;
        _editingId = null;
        _replacesId = null;
        _seed = null;
      } else {
        _formError =
            widget.repository.banner ??
            'Error de desament. Les dades anteriors es conserven.';
      }
    });
    widget.onHistoryChanged?.call(_history);
  }

  @override
  Widget build(BuildContext context) {
    final correcting = _replacesId != null && _editingId == null;
    final draftLabel = correcting
        ? 'Desa la revisió com a esborrany'
        : _editingId != null
        ? 'Actualitza l\'esborrany'
        : 'Desa esborrany';
    final validateLabel = correcting ? 'Valida la revisió' : 'Valida';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _mode(oeeCalculationModeKey, false, 'Càlcul'),
            _mode(oeeHistoryModeKey, true, 'Històric'),
          ],
        ),
        const SizedBox(height: 8),
        if (_history)
          OeeHistoryBrowser(
            repository: widget.repository,
            initialLineId: widget.line.id,
            initialOpenId: _openId,
            onNew: () {
              setState(_clearEditor);
              widget.onHistoryChanged?.call(false);
            },
            onCorrect: (record) {
              setState(() => _applyRecord(record));
              widget.onHistoryChanged?.call(false);
            },
            onEdit: (record) {
              setState(() => _applyRecord(record));
              widget.onHistoryChanged?.call(false);
            },
          )
        else ...[
          if (correcting)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Correcció. El registre validat no es modifica.'),
            ),
          _metaField(oeeDateKey, _date, 'Data de producció', 'AAAA-MM-DD'),
          _metaField(oeeShiftKey, _shift, 'Torn', null),
          _metaField(oeeArticleKey, _article, 'Article', null),
          _metaField(oeeLotKey, _lot, 'Lot', 'Opcional'),
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formError!,
                style: const TextStyle(color: Color(0xFF8C3A3A)),
              ),
            ),
          const SizedBox(height: 8),
          OeeEnginePanel(
            lineName: widget.line.name,
            seed: _seed,
            seedToken: _seedToken,
            draftLabel: draftLabel,
            validateLabel: validateLabel,
            onSaveDraft: (inputs) => _save(inputs, OeeRecordStatus.draft),
            onSaveValidated: (inputs) =>
                _save(inputs, OeeRecordStatus.validated),
          ),
          if (correcting || _editingId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: oeeCancelEditKey,
              focusNode: _cancelFocus,
              style: workspaceControlStyle,
              onPressed: () {
                setState(() {
                  _history = true;
                  _formError = null;
                });
                widget.onHistoryChanged?.call(true);
              },
              child: const Text('Cancel·la'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _mode(Key key, bool history, String label) {
    final active = _history == history;
    return OutlinedButton(
      key: key,
      style: workspaceControlStyle,
      onPressed: () {
        setState(() => _history = history);
        widget.onHistoryChanged?.call(history);
      },
      child: Text(active ? 'Activa: $label' : label),
    );
  }

  Widget _metaField(
    Key key,
    TextEditingController controller,
    String label,
    String? hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: key,
        controller: controller,
        focusNode: key == oeeArticleKey ? _articleFocus : null,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class OeeHistoryBrowser extends StatefulWidget {
  const OeeHistoryBrowser({
    super.key,
    required this.repository,
    this.initialLineId,
    this.initialOpenId,
    this.onNew,
    this.onCorrect,
    this.onEdit,
    this.onClose,
  });

  final WorkspaceRepository repository;
  final String? initialLineId;
  final String? initialOpenId;
  final VoidCallback? onNew;
  final ValueChanged<OeeRecord>? onCorrect;
  final ValueChanged<OeeRecord>? onEdit;
  final VoidCallback? onClose;

  @override
  State<OeeHistoryBrowser> createState() => _OeeHistoryBrowserState();
}

class _OeeHistoryBrowserState extends State<OeeHistoryBrowser> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _shift = TextEditingController();
  final _article = TextEditingController();
  final _lot = TextEditingController();

  late String _lineValue = widget.initialLineId ?? '';
  var _scope = OeeRecordScope.validated;
  var _lotMode = OeeLotMode.any;
  String? _openId;
  final _detailKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _openId = widget.initialOpenId;
    widget.repository.addListener(_onRepo);
    _revealDetail();
  }

  void _revealDetail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _detailKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.05);
      }
    });
  }

  void _showRecord(String? id) {
    setState(() => _openId = id);
    if (id != null) {
      _revealDetail();
    }
  }

  @override
  void didUpdateWidget(OeeHistoryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOpenId != oldWidget.initialOpenId &&
        widget.initialOpenId != null) {
      _openId = widget.initialOpenId;
      _revealDetail();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepo);
    _from.dispose();
    _to.dispose();
    _shift.dispose();
    _article.dispose();
    _lot.dispose();
    super.dispose();
  }

  void _onRepo() {
    if (mounted) {
      setState(() {});
    }
  }

  OeeHistoryQuery get _query {
    return OeeHistoryQuery(
      from: _from.text,
      to: _to.text,
      shift: _shift.text,
      lineId: _lineValue.isEmpty ? null : _lineValue,
      article: _article.text,
      lotMode: _lotMode,
      lot: _lot.text,
      scope: _scope,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = widget.repository.workspace;
    final open = _openId == null ? null : findOeeRecord(workspace, _openId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Històric OEE',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(oeeNoAggregationMessage),
        if (widget.onClose != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: oeeCloseHistoryKey,
            style: workspaceControlStyle,
            onPressed: widget.onClose,
            child: const Text('Tanca l\'històric'),
          ),
        ],
        if (open != null)
          _detail(workspace, open)
        else ...[
          const SizedBox(height: 8),
          _filters(workspace),
          const SizedBox(height: 8),
          if (widget.onNew != null)
            FilledButton(
              key: oeeNewRecordKey,
              style: workspaceControlStyle,
              onPressed: widget.onNew,
              child: const Text('Nou registre'),
            ),
          const SizedBox(height: 8),
          ..._list(workspace),
        ],
      ],
    );
  }

  Widget _filters(Workspace workspace) {
    final options = oeeLineOptions(workspace);
    final known = options.any((option) => (option.lineId ?? '') == _lineValue);
    final lineValue = known ? _lineValue : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _scopeButton(oeeScopeValidatedKey, OeeRecordScope.validated, 'Validats'),
            _scopeButton(oeeScopeDraftKey, OeeRecordScope.drafts, 'Esborranys'),
            _scopeButton(oeeScopeAllKey, OeeRecordScope.all, 'Tots'),
          ],
        ),
        _filterField(oeeFilterFromKey, _from, 'Des de', 'AAAA-MM-DD'),
        _filterField(oeeFilterToKey, _to, 'Fins a', 'AAAA-MM-DD'),
        _filterField(oeeFilterShiftKey, _shift, 'Torn', null),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DropdownButton<String>(
            key: oeeLineFilterKey,
            isExpanded: true,
            value: lineValue,
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option.lineId ?? '',
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() {
              _lineValue = value ?? '';
            }),
          ),
        ),
        _filterField(oeeFilterArticleKey, _article, 'Article', null),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _lotButton(oeeLotAnyKey, OeeLotMode.any, 'Qualsevol lot'),
            _lotButton(oeeLotEmptyKey, OeeLotMode.empty, 'Sense lot'),
            _lotButton(oeeLotExactKey, OeeLotMode.exact, 'Lot concret'),
          ],
        ),
        if (_lotMode == OeeLotMode.exact)
          _filterField(oeeFilterLotKey, _lot, 'Lot', null),
      ],
    );
  }

  List<Widget> _list(Workspace workspace) {
    final view = queryOeeHistory(workspace, _query);
    if (view.records.isEmpty) {
      return [
        for (final message in view.messages)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
      ];
    }
    return [
      for (final record in view.records)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton(
            key: oeeOpenRecordKey(record.id),
            style: workspaceControlStyle.copyWith(
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => _showRecord(record.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.productionDate} · ${record.shift} · ${record.article}',
                ),
                Text(record.lot == null ? 'Sense lot' : 'Lot ${record.lot}'),
                Text(_statusText(record)),
                Text(oeeRecordIndicatorLabel(record)),
                Text(record.capturedLineName),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _detail(Workspace workspace, OeeRecord record) {
    final computation = computationForRecord(record);
    final note = lineContextNote(workspace, record);
    final previous = record.replacesId == null
        ? null
        : findOeeRecord(workspace, record.replacesId!);
    final kept = replacedValidatedIds(workspace).contains(record.id);
    final line = findAsset(workspace, record.lineId);
    final lineAlive = line != null && line.kind == AssetKind.line;
    return _Reveal(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Estat: ${_statusText(record)}'),
        Text('Data de producció: ${record.productionDate}'),
        Text('Torn: ${record.shift}'),
        Text('Article: ${record.article}'),
        Text(record.lot == null ? 'Lot: Sense lot' : 'Lot: ${record.lot}'),
        Text('Línia capturada: ${record.capturedLineName}'),
        Text('Planta capturada: ${record.capturedPlantName}'),
        Text(
          'P ${formatEngineQuantity(record.plannedMinutes)} min · S ${formatEngineQuantity(record.downtimeMinutes)} min',
        ),
        Text(
          'Velocitat ${formatEngineQuantity(record.speedOriginal)} ${speedUnitLabel(record.speedUnit)} · c ${formatEngineQuantity(record.idealCycleSeconds)} s/unitat',
        ),
        Text('N ${record.totalUnits} · G ${record.goodUnits}'),
        Text('Fórmula ${record.formulaVersion}'),
        if (note != null) Text(note),
        if (kept)
          const Text(
            'Aquesta revisió s\'ha conservat. La vista mostra la revisió posterior.',
          ),
        const SizedBox(height: 8),
        OeeEngineResultCard(
          reading: OeeTextResult(
            issues: computation.issues,
            outcome: computation.outcome,
          ),
          hideStoredMessage: true,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: oeeCloseRecordKey,
          style: workspaceControlStyle,
          onPressed: () => _showRecord(null),
          child: const Text('Tanca'),
        ),
        if (previous != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: oeePreviousRevisionKey,
            style: workspaceControlStyle,
            onPressed: () => _showRecord(previous.id),
            child: const Text('Revisió anterior'),
          ),
        ],
        if (record.status == OeeRecordStatus.draft &&
            lineAlive &&
            widget.onEdit != null) ...[
          const SizedBox(height: 8),
          FilledButton(
            style: workspaceControlStyle,
            onPressed: () => widget.onEdit!(record),
            child: const Text('Edita'),
          ),
        ],
        if (record.status == OeeRecordStatus.validated &&
            lineAlive &&
            widget.onCorrect != null) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: oeeCorrectKey,
            style: workspaceControlStyle,
            onPressed: () => widget.onCorrect!(record),
            child: const Text('Corregeix'),
          ),
        ],
      ],
      ),
    );
  }

  Widget _filterField(
    Key key,
    TextEditingController controller,
    String label,
    String? hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: key,
        controller: controller,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _scopeButton(Key key, OeeRecordScope scope, String label) {
    final active = _scope == scope;
    return OutlinedButton(
      key: key,
      style: workspaceControlStyle,
      onPressed: () => setState(() => _scope = scope),
      child: Text(active ? 'Activa: $label' : label),
    );
  }

  Widget _lotButton(Key key, OeeLotMode mode, String label) {
    final active = _lotMode == mode;
    return OutlinedButton(
      key: key,
      style: workspaceControlStyle,
      onPressed: () => setState(() => _lotMode = mode),
      child: Text(active ? 'Activa: $label' : label),
    );
  }

  String _statusText(OeeRecord record) {
    return record.status == OeeRecordStatus.draft ? 'Esborrany' : 'Validat';
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(context, alignment: 0.05);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
