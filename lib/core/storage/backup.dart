import 'dart:convert';

import '../models/global_state.dart';
import '../models/session.dart';

/// A full copy of the user's saved data, used for export and import.
class BackupData {
  const BackupData({required this.global, required this.sessions});

  final GlobalState global;
  final List<Session> sessions;
}

const _format = 'sushi-tracker-backup';
const _formatVersion = 1;

String encodeBackup(BackupData data, {DateTime? exportedAt}) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': _format,
      'version': _formatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'global': {
        'taps': data.global.lifetimeTotalTaps,
        'sessions': data.global.lifetimeTotalSessions,
        'epoch': data.global.epoch,
        'resetAt': data.global.lastResetAt?.millisecondsSinceEpoch,
      },
      'sessions': [
        for (final session in data.sessions)
          {
            'id': session.id,
            'startedAt': session.startedAt.millisecondsSinceEpoch,
            'endedAt': session.endedAt.millisecondsSinceEpoch,
            'count': session.count,
            'durationSeconds': session.durationSeconds,
            'epoch': session.contributionEpoch,
            if (session.priceCents != null) 'priceCents': session.priceCents,
            if (session.restaurant != null) 'restaurant': session.restaurant,
            if (session.companions.isNotEmpty)
              'companions': [for (final c in session.companions) c.toMap()],
          },
      ],
    });

/// Parses and validates a backup. Throws [FormatException] for anything that
/// is not a complete, well-formed Sushi Tracker backup.
BackupData decodeBackup(String source) {
  final Object? root;
  try {
    root = jsonDecode(source.trim());
  } on FormatException {
    throw const FormatException('Not valid JSON');
  }
  if (root is! Map ||
      root['format'] != _format ||
      root['version'] != _formatVersion) {
    throw const FormatException('Not a Sushi Tracker backup');
  }
  final global = root['global'];
  final sessions = root['sessions'];
  if (global is! Map || sessions is! List) {
    throw const FormatException('Backup is incomplete');
  }
  final ids = <String>{};
  final parsed = [
    for (final raw in sessions)
      if (raw is Map)
        _session(raw)
      else
        throw const FormatException('Invalid session'),
  ];
  for (final session in parsed) {
    if (!ids.add(session.id)) {
      throw const FormatException('Duplicate session');
    }
  }
  final resetAt = global['resetAt'];
  final epoch = _nonNegative(global['epoch']);
  // A session from a later lifetime than the totals would stay hidden now
  // and be miscounted after the next reset.
  if (parsed.any((session) => session.contributionEpoch > epoch)) {
    throw const FormatException('Invalid session');
  }
  return BackupData(
    global: GlobalState(
      lifetimeTotalTaps: _nonNegative(global['taps']),
      lifetimeTotalSessions: _nonNegative(global['sessions']),
      epoch: epoch,
      lastResetAt: resetAt == null ? null : _date(resetAt),
    ),
    sessions: parsed,
  );
}

Session _session(Map<dynamic, dynamic> raw) {
  final id = raw['id'];
  if (id is! String || id.isEmpty) {
    throw const FormatException('Invalid session');
  }
  final startedAt = _date(raw['startedAt']);
  final endedAt = _date(raw['endedAt']);
  final count = _nonNegative(raw['count']);
  final durationSeconds = _nonNegative(raw['durationSeconds']);
  final epoch = _int(raw['epoch']);
  if (count == 0 ||
      endedAt.isBefore(startedAt) ||
      epoch < Session.unattributedEpoch) {
    throw const FormatException('Invalid session');
  }
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    count: count,
    durationSeconds: durationSeconds,
    contributionEpoch: epoch,
    priceCents: raw['priceCents'] == null
        ? null
        : _nonNegative(raw['priceCents']),
    restaurant: _restaurant(raw['restaurant']),
    companions: _companions(raw['companions']),
  );
}

List<Companion> _companions(Object? value) {
  final companions = Companion.listFromRaw(value);
  final names = {for (final c in companions) c.name.toLowerCase()};
  if (names.length != companions.length) {
    throw const FormatException('Duplicate companion');
  }
  return companions;
}

String? _restaurant(Object? value) {
  if (value == null) return null;
  if (value is! String || value.length > Session.maxRestaurantLength) {
    throw const FormatException('Invalid restaurant');
  }
  return Session.normalizeRestaurant(value);
}

int _int(Object? value) {
  if (value is int) return value;
  throw const FormatException('Invalid number');
}

/// Milliseconds since the epoch, within what [DateTime] can represent.
DateTime _date(Object? value) {
  final millis = _int(value);
  if (millis.abs() > _maxMillis) throw const FormatException('Invalid date');
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

const _maxMillis = 8640000000000000;

int _nonNegative(Object? value) {
  final number = _int(value);
  if (number < 0) throw const FormatException('Invalid number');
  return number;
}
