import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/arrival.dart';
import '../providers/arrival_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../services/analytics_service.dart';
import '../services/arrival_platform.dart';
import '../theme/app_colors.dart';
import '../widgets/arrival/arrival_format.dart';
import '../widgets/arrival/arrival_scaffold.dart';
import '../widgets/content_card.dart';
import '../widgets/icon_badge.dart';

// Feature arrival — add / edit a place (design §4, mock `place.html`):
// name + icon → find the address → confirm → save. Every route of the flow
// is named `ArrivalPlace/…` so saving pops the whole flow in one go.

const String _flow = 'ArrivalPlace/';

Route<T> _route<T>(String name, WidgetBuilder builder) => MaterialPageRoute<T>(
  settings: RouteSettings(name: '$_flow$name'),
  builder: builder,
);

void _popFlow(BuildContext context) => Navigator.of(
  context,
).popUntil((r) => !(r.settings.name ?? '').startsWith(_flow));

/// "+ Thêm nơi": name + icon first. No-op when all 4 custom slots are taken.
Future<void> openArrivalNewPlace(BuildContext context) async {
  final slot = context.read<ArrivalProvider>().nextFreeSlot;
  if (slot == null) return;
  await Navigator.of(
    context,
  ).push(_route<void>('Name', (_) => ArrivalNameScreen(slot: slot)));
}

/// Straight to "… ở đâu?" for [draft] (Home skips the name step).
Future<void> openArrivalPlaceSearch(BuildContext context, ArrivalPlace draft) =>
    Navigator.of(
      context,
    ).push(_route<void>('Search', (_) => ArrivalSearchScreen(draft: draft)));

/// Edit a place (Home: only its location).
Future<void> openArrivalEditPlace(BuildContext context, ArrivalPlace place) =>
    Navigator.of(context).push(
      _route<void>(
        'Edit',
        (_) => place.isHome
            ? ArrivalEditHomeScreen(home: place)
            : ArrivalEditPlaceScreen(place: place),
      ),
    );

String _myName(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final couple = context.read<CoupleProvider>().couple;
  final uid = context.read<AuthProvider>().currentUser?.id;
  return couple == null
      ? l10n.sleepYou
      : ArrivalFormat.myName(l10n, couple, uid);
}

String _partnerName(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final couple = context.read<CoupleProvider>().couple;
  final uid = context.read<AuthProvider>().currentUser?.id;
  return couple == null
      ? l10n.reactionPartnerFallback
      : ArrivalFormat.partnerName(l10n, couple, uid);
}

// ── Name + icon ─────────────────────────────────────────────────────────────

/// Chip → (name, icon) (design §4.1).
List<(String, ArrivalIcon)> _chips(AppLocalizations l10n) => [
  (l10n.arrivalChipWork, ArrivalIcon.work),
  (l10n.arrivalChipSchool, ArrivalIcon.school),
  (l10n.arrivalChipFamily, ArrivalIcon.family),
  (l10n.arrivalChipGym, ArrivalIcon.gym),
  (l10n.arrivalChipCafe, ArrivalIcon.cafe),
];

class ArrivalNameScreen extends StatefulWidget {
  const ArrivalNameScreen({super.key, required this.slot});

  final String slot;

  @override
  State<ArrivalNameScreen> createState() => _ArrivalNameScreenState();
}

class _ArrivalNameScreenState extends State<ArrivalNameScreen> {
  final _name = TextEditingController();
  ArrivalIcon _icon = ArrivalIcon.pin;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    final name = normalizeArrivalName(_name.text);
    if (name == null) return;
    openArrivalPlaceSearch(
      context,
      ArrivalPlace(slot: widget.slot, name: name, icon: _icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = normalizeArrivalName(_name.text) != null;
    return ArrivalScaffold(
      title: l10n.arrivalNewPlaceTitle,
      bottom: [
        ArrivalPrimaryButton(
          key: const ValueKey('arrival-continue'),
          label: l10n.arrivalContinue,
          onPressed: valid ? _next : null,
        ),
        if (!valid)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.arrivalNameEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.78),
                fontSize: 12,
              ),
            ),
          ),
      ],
      children: [
        const SizedBox(height: 12),
        _NameField(controller: _name, autofocus: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, icon) in _chips(l10n))
              _Chip(
                label: label,
                selected: _name.text.trim() == label,
                onTap: () {
                  _name.text = label;
                  _name.selection = TextSelection.collapsed(
                    offset: label.length,
                  );
                  setState(() => _icon = icon);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        _IconPicker(value: _icon, onChanged: (i) => setState(() => _icon = i)),
        const SizedBox(height: 8),
        Text(
          l10n.arrivalIconAuto,
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.78),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        if (valid)
          _PreviewBox(
            partner: _partnerName(context),
            line: l10n.arrivalWidgetPlace(
              _myName(context),
              normalizeArrivalName(_name.text)!,
            ),
          ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    this.autofocus = false,
    this.note,
  });

  final TextEditingController controller;
  final bool autofocus;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.arrivalNameLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('arrival-name'),
          controller: controller,
          autofocus: autofocus,
          maxLength: kArrivalNameMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            fillColor: Colors.white,
            hintText: l10n.arrivalNameHint,
            helperText: note ?? l10n.arrivalNameNote,
            helperStyle: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.78),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.textPrimary
            : Colors.white.withValues(alpha: 0.72),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.value, required this.onChanged});

  final ArrivalIcon value;
  final ValueChanged<ArrivalIcon> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.arrivalIconLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final icon in ArrivalIcon.values)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: icon == value,
                label: ArrivalFormat.iconLabel(l10n, icon),
                button: true,
                excludeSemantics: true,
                child: Material(
                  color: icon == value
                      ? AppColors.textPrimary
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onChanged(icon),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        ArrivalFormat.icon(icon),
                        size: 20,
                        color: icon == value
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.partner, required this.line});

  final String partner;
  final String line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              TextSpan(text: '${l10n.arrivalPreviewLead(partner)} '),
              TextSpan(
                text: line,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search ──────────────────────────────────────────────────────────────────

enum _SearchState { idle, searching, results, empty, offline, error }

class ArrivalSearchScreen extends StatefulWidget {
  const ArrivalSearchScreen({super.key, required this.draft});

  final ArrivalPlace draft;

  @override
  State<ArrivalSearchScreen> createState() => _ArrivalSearchScreenState();
}

class _ArrivalSearchScreenState extends State<ArrivalSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _token = 0;
  bool? _available;
  _SearchState _state = _SearchState.idle;
  List<PlaceSearchResult> _results = const [];

  PlaceSearch get _search => context.read<ArrivalProvider>().placeSearch;

  @override
  void initState() {
    super.initState();
    _search.isAvailable().then((ok) {
      if (!mounted) return;
      setState(() => _available = ok);
      if (!ok) _logSearch('unavailable');
    }, onError: (_) => mounted ? setState(() => _available = false) : null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _logSearch(String result) =>
      AnalyticsService.instance.logArrivalAddressSearch(
        result: result,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

  void _onChanged(String text) {
    setState(() {}); // clear button
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      _token++;
      setState(() {
        _state = _SearchState.idle;
        _results = const [];
      });
      return;
    }
    final wait = _search.suggestsWhileTyping
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 800);
    _debounce = Timer(wait, () => _run(text));
  }

  Future<void> _run(String text) async {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) return;
    final token = ++_token;
    setState(() => _state = _SearchState.searching);
    _SearchState next;
    var results = const <PlaceSearchResult>[];
    try {
      results = await _search.search(query);
      next = results.isEmpty ? _SearchState.empty : _SearchState.results;
    } on PlaceSearchOffline {
      next = _SearchState.offline;
    } on PlaceSearchUnavailable {
      if (mounted && token == _token) setState(() => _available = false);
      _logSearch('unavailable');
      return;
    } catch (_) {
      next = _SearchState.error;
    }
    if (!mounted || token != _token) return; // a newer query is running
    setState(() {
      _state = next;
      _results = results;
    });
    switch (next) {
      case _SearchState.empty:
        _logSearch('not_found');
      case _SearchState.offline:
        _logSearch('offline');
      case _SearchState.error:
        _logSearch('error');
      default:
        break;
    }
  }

  void _pick(PlaceSearchResult r) {
    _logSearch('picked');
    Navigator.of(context).push(
      _route<void>(
        'Confirm',
        (_) => ArrivalConfirmScreen(
          draft: widget.draft,
          location: ArrivalLocation(
            lat: r.lat,
            lng: r.lng,
            source: ArrivalLocationSource.address,
            savedAt: DateTime.now(),
            address: r.address,
          ),
          hasHouseNumber: r.hasHouseNumber,
          approximate: r.approximate,
        ),
      ),
    );
  }

  void _useCurrent() => Navigator.of(context).push(
    _route<void>('Current', (_) => ArrivalCurrentScreen(draft: widget.draft)),
  );

  Future<void> _nameOnly() async {
    final ok = await context.read<ArrivalProvider>().savePlace(widget.draft);
    if (!mounted) return;
    if (ok) _savedSnack(context, widget.draft);
    _popFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final placeName = ArrivalFormat.placeName(l10n, widget.draft);
    final title = l10n.arrivalWhereTitle(placeName);
    if (_available == false) {
      return ArrivalScaffold(
        title: title,
        bottom: [
          ArrivalPrimaryButton(
            label: l10n.arrivalUseCurrent,
            icon: IconsaxPlusLinear.gps,
            onPressed: _useCurrent,
          ),
          if (!widget.draft.isHome)
            ArrivalTextButton(
              label: l10n.arrivalNameOnly,
              onPressed: _nameOnly,
            ),
        ],
        children: [ArrivalBody(l10n.arrivalNoGeocoder)],
      );
    }
    final problem = switch (_state) {
      _SearchState.empty => l10n.arrivalNoResults,
      _SearchState.offline => l10n.arrivalSearchOffline,
      _SearchState.error => l10n.arrivalSearchError,
      _ => null,
    };
    return ArrivalScaffold(
      title: title,
      bottom: [
        if (problem != null)
          ArrivalPrimaryButton(
            label: l10n.arrivalUseCurrent,
            icon: IconsaxPlusLinear.gps,
            onPressed: _useCurrent,
          ),
      ],
      children: [
        ArrivalBody(l10n.arrivalWhereSub, muted: true),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('arrival-search'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _run,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            fillColor: Colors.white,
            hintText: l10n.arrivalSearchHint,
            prefixIcon: const Icon(
              IconsaxPlusLinear.search_normal,
              size: 20,
              color: AppColors.textPrimary,
            ),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.arrivalClearSearch,
                    icon: const Icon(IconsaxPlusLinear.close_circle, size: 18),
                    onPressed: () {
                      _query.clear();
                      _onChanged('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (problem != null)
          Semantics(
            liveRegion: true,
            child: ContentCard(
              child: Text(
                problem,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: ContentCard(
              key: ValueKey(_state),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  if (_state == _SearchState.searching)
                    Semantics(
                      liveRegion: true,
                      child: _ResultRow(
                        leading: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: l10n.arrivalSearching,
                      ),
                    ),
                  if (_state == _SearchState.results)
                    for (final r in _results.take(5))
                      _ResultRow(
                        leading: const Icon(
                          IconsaxPlusLinear.location,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        title: r.title,
                        subtitle: r.subtitle,
                        onTap: () => _pick(r),
                      ),
                  _ResultRow(
                    key: const ValueKey('arrival-use-current'),
                    leading: const Icon(
                      IconsaxPlusLinear.gps,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    title: l10n.arrivalUseCurrentRow,
                    subtitle: l10n.arrivalUseCurrentRowSub,
                    underline: true,
                    onTap: _useCurrent,
                  ),
                ],
              ),
            ),
          ),
        if (!_search.suggestsWhileTyping && _state == _SearchState.results)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.arrivalSearchTip,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.78),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.underline = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: underline
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Current location ────────────────────────────────────────────────────────

enum _ReadState { intro, reading, timeout, precise }

class ArrivalCurrentScreen extends StatefulWidget {
  const ArrivalCurrentScreen({super.key, required this.draft});

  final ArrivalPlace draft;

  @override
  State<ArrivalCurrentScreen> createState() => _ArrivalCurrentScreenState();
}

class _ArrivalCurrentScreenState extends State<ArrivalCurrentScreen> {
  _ReadState _state = _ReadState.intro;

  Future<void> _read() async {
    final arrival = context.read<ArrivalProvider>();
    var s = await arrival.permissions.status();
    if (!s.canReadOnce) {
      s = await arrival.permissions.requestWhenInUse();
      AnalyticsService.instance.logArrivalPermission(
        step: 'when_in_use',
        result: !s.canReadOnce
            ? 'denied'
            : s.precise
            ? 'granted'
            : 'approximate',
      );
    }
    if (!mounted) return;
    if (!s.canReadOnce) {
      // D8.1: back to the address box, never asked again on its own.
      Navigator.of(context).pop();
      return;
    }
    if (!s.precise) {
      setState(() => _state = _ReadState.precise);
      return;
    }
    setState(() => _state = _ReadState.reading);
    CurrentFix? fix;
    try {
      fix = await arrival.location.current();
    } catch (_) {
      fix = null;
    }
    if (!mounted) return;
    if (fix == null) {
      setState(() => _state = _ReadState.timeout);
      return;
    }
    final f = fix;
    Navigator.of(context).pushReplacement(
      _route<void>(
        'Confirm',
        (_) => ArrivalConfirmScreen(
          draft: widget.draft,
          location: ArrivalLocation(
            lat: f.lat,
            lng: f.lng,
            source: ArrivalLocationSource.current,
            savedAt: DateTime.now(),
          ),
          accuracyM: f.accuracyM.round(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arrival = context.read<ArrivalProvider>();
    final name = ArrivalFormat.placeName(l10n, widget.draft);
    if (_state == _ReadState.precise) {
      return ArrivalScaffold(
        title: l10n.arrivalPreciseTitle,
        bottom: [
          ArrivalPrimaryButton(
            label: l10n.arrivalOpenSettings,
            onPressed: arrival.permissions.openSettings,
          ),
          ArrivalTextButton(label: l10n.arrivalReadLocation, onPressed: _read),
        ],
        children: [ArrivalBody(l10n.arrivalPreciseBody)],
      );
    }
    final reading = _state == _ReadState.reading;
    return ArrivalScaffold(
      title: l10n.arrivalCurrentTitle(name),
      bottom: [
        ArrivalPrimaryButton(
          key: const ValueKey('arrival-read'),
          label: reading ? l10n.arrivalReading : l10n.arrivalReadLocation,
          icon: IconsaxPlusLinear.gps,
          busy: reading,
          onPressed: _read,
        ),
        ArrivalTextButton(
          label: l10n.arrivalBackToSearch,
          onPressed: reading ? null : () => Navigator.of(context).pop(),
        ),
      ],
      children: [
        ArrivalBody(l10n.arrivalCurrentBody),
        const SizedBox(height: 16),
        ArrivalHintBox(l10n.arrivalCurrentHint),
        if (_state == _ReadState.timeout) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: ArrivalWarnBox(l10n.arrivalReadTimeout),
          ),
        ],
      ],
    );
  }
}

// ── Confirm (D21) ───────────────────────────────────────────────────────────

class ArrivalConfirmScreen extends StatelessWidget {
  const ArrivalConfirmScreen({
    super.key,
    required this.draft,
    required this.location,
    this.hasHouseNumber = true,
    this.approximate = false,
    this.accuracyM,
  });

  final ArrivalPlace draft;
  final ArrivalLocation location;
  final bool hasHouseNumber;
  final bool approximate;

  /// Only for "current location": "lệch khoảng 12 m".
  final int? accuracyM;

  Future<void> _save(BuildContext context) async {
    final arrival = context.read<ArrivalProvider>();
    final place = draft.withLocation(location);
    final ok = await arrival.savePlace(place);
    if (!context.mounted) return;
    if (ok) {
      AnalyticsService.instance.logArrivalPlaceSaved(
        slot: place.isHome ? 'home' : 'custom',
        source: location.source.name,
        icon: place.isHome ? 'home' : (place.icon ?? ArrivalIcon.pin).name,
        hasHouseNumber: hasHouseNumber && !approximate,
      );
      _savedSnack(context, place);
    }
    _popFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = location.source == ArrivalLocationSource.current;
    final name = ArrivalFormat.placeName(l10n, draft);
    return ArrivalScaffold(
      title: l10n.arrivalConfirmTitle,
      bottom: [
        ArrivalPrimaryButton(
          key: const ValueKey('arrival-save'),
          label: l10n.arrivalSave,
          onPressed: () => _save(context),
        ),
        ArrivalTextButton(
          label: current ? l10n.arrivalReread : l10n.arrivalWrongSpot,
          underline: !current,
          onPressed: () => Navigator.of(context).pushReplacement(
            _route<void>('Current', (_) => ArrivalCurrentScreen(draft: draft)),
          ),
        ),
      ],
      children: [
        const SizedBox(height: 8),
        ContentCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    ArrivalFormat.placeIcon(draft),
                    tint: AppColors.textPrimary,
                    tintAlpha: 0.06,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          current
                              ? l10n.arrivalFromCurrent(accuracyM ?? 0)
                              : l10n.arrivalFromAddress,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (location.address != null) ...[
                const SizedBox(height: 14),
                Text(
                  location.address!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.arrivalRadiusLine(location.radius),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (!current && (approximate || !hasHouseNumber)) ...[
                const SizedBox(height: 12),
                ArrivalWarnBox(
                  approximate
                      ? l10n.arrivalConfirmAlleyWarn
                      : l10n.arrivalNoHouseNumber,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

void _savedSnack(BuildContext context, ArrivalPlace place) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.arrivalSaved(ArrivalFormat.placeName(l10n, place))),
      ),
    );
}

// ── Edit ────────────────────────────────────────────────────────────────────

class ArrivalEditPlaceScreen extends StatefulWidget {
  const ArrivalEditPlaceScreen({super.key, required this.place});

  final ArrivalPlace place;

  @override
  State<ArrivalEditPlaceScreen> createState() => _ArrivalEditPlaceScreenState();
}

class _ArrivalEditPlaceScreenState extends State<ArrivalEditPlaceScreen> {
  late final _name = TextEditingController(text: widget.place.name);
  late ArrivalIcon _icon = widget.place.icon ?? ArrivalIcon.pin;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The live place (the location may have changed in the search flow).
  ArrivalPlace get _current =>
      context
          .read<ArrivalProvider>()
          .places
          .where((p) => p.slot == widget.place.slot)
          .firstOrNull ??
      widget.place;

  ArrivalPlace? get _edited {
    final name = normalizeArrivalName(_name.text);
    if (name == null) return null;
    return ArrivalPlace(
      slot: widget.place.slot,
      name: name,
      icon: _icon,
      location: _current.location,
    );
  }

  Future<void> _save() async {
    final p = _edited;
    if (p == null) return;
    final ok = await context.read<ArrivalProvider>().savePlace(p);
    if (!mounted) return;
    if (ok) _savedSnack(context, p);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final name = widget.place.name ?? '';
    final yes = await _confirmDelete(
      context,
      title: l10n.arrivalDeletePlaceTitle(name),
      body: l10n.arrivalDeletePlaceBody,
    );
    if (!yes || !mounted) return;
    await deleteArrivalPlaceWithUndo(context, widget.place.slot);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    context.watch<ArrivalProvider>();
    final edited = _edited;
    final changed =
        edited != null &&
        (edited.name != widget.place.name || edited.icon != widget.place.icon);
    return ArrivalScaffold(
      title: l10n.arrivalEditTitle(widget.place.name ?? ''),
      bottom: [
        ArrivalPrimaryButton(
          key: const ValueKey('arrival-edit-save'),
          label: l10n.arrivalSave,
          onPressed: changed ? _save : null,
        ),
      ],
      children: [
        const SizedBox(height: 12),
        _NameField(controller: _name, note: l10n.arrivalRenameNote),
        const SizedBox(height: 16),
        _IconPicker(value: _icon, onChanged: (i) => setState(() => _icon = i)),
        const SizedBox(height: 24),
        _LocationRow(
          place: _current,
          onTap: () => openArrivalPlaceSearch(context, edited ?? _current),
        ),
        const SizedBox(height: 24),
        _DangerRow(
          key: const ValueKey('arrival-delete'),
          title: l10n.arrivalDeletePlace,
          subtitle: l10n.arrivalDeletePlaceSub,
          onTap: _delete,
        ),
      ],
    );
  }
}

class ArrivalEditHomeScreen extends StatelessWidget {
  const ArrivalEditHomeScreen({super.key, required this.home});

  final ArrivalPlace home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final live = context.watch<ArrivalProvider>().home;
    return ArrivalScaffold(
      title: l10n.arrivalHomeName,
      children: [
        ArrivalBody(l10n.arrivalHomeEditBody, muted: true),
        const SizedBox(height: 20),
        _LocationRow(
          place: live,
          onTap: () => openArrivalPlaceSearch(context, live),
        ),
        if (live.location != null) ...[
          const SizedBox(height: 24),
          _DangerRow(
            key: const ValueKey('arrival-delete'),
            title: l10n.arrivalDeleteHomeAddress,
            subtitle: l10n.arrivalDeleteHomeAddressSub,
            onTap: () async {
              final yes = await _confirmDelete(
                context,
                title: l10n.arrivalDeleteHomeAddressTitle,
                body: l10n.arrivalDeleteHomeAddressBody,
              );
              if (!yes || !context.mounted) return;
              await deleteArrivalPlaceWithUndo(context, kArrivalHome);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

/// "Vị trí" label + one card row (address / "Lưu bằng vị trí hiện tại" /
/// "Chưa đặt địa chỉ") → search.
class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.place, required this.onTap});

  final ArrivalPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loc = place.location;
    final title = loc == null
        ? l10n.arrivalNoAddressYet
        : loc.address != null
        ? ArrivalFormat.shortAddress(loc.address!)
        : l10n.arrivalUseCurrent;
    final sub = loc == null
        ? l10n.arrivalNoAddressManual
        : loc.source == ArrivalLocationSource.current
        ? l10n.arrivalSavedFromCurrent(ArrivalFormat.shortDate(loc.savedAt))
        : l10n.arrivalSavedFromAddress(ArrivalFormat.shortDate(loc.savedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.arrivalLocationLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ContentCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            key: const ValueKey('arrival-location-row'),
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    ArrivalFormat.placeIcon(place),
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          sub,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                IconsaxPlusLinear.trash,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(false),
          child: Text(l10n.arrivalCancel),
        ),
        TextButton(
          key: const ValueKey('arrival-delete-confirm'),
          onPressed: () => Navigator.of(d).pop(true),
          child: Text(l10n.arrivalDelete),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// Deletes [slot] (Home: only its address) and offers "Hoàn tác" for 5 s
/// (Lead 2026-10-20). The last place with a location gone → auto switches
/// off with it (design §4.6); undo switches it back.
Future<void> deleteArrivalPlaceWithUndo(
  BuildContext context,
  String slot,
) async {
  final l10n = AppLocalizations.of(context);
  final arrival = context.read<ArrivalProvider>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final hadAuto = arrival.wantsAuto;
  final removed = await arrival.deletePlace(slot);
  if (removed == null) return;
  AnalyticsService.instance.logArrivalPlaceDeleted(
    removed.isHome ? 'home_address' : 'custom',
  );
  final autoDropped = hadAuto && arrival.placesWithLocation.isEmpty;
  if (autoDropped) await arrival.setWantsAuto(false);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          removed.isHome
              ? l10n.arrivalHomeAddressDeleted
              : l10n.arrivalDeleted(removed.name ?? ''),
        ),
        action: SnackBarAction(
          label: l10n.arrivalUndo,
          onPressed: () async {
            await arrival.savePlace(removed);
            if (autoDropped) await arrival.setWantsAuto(true);
          },
        ),
      ),
    );
}
