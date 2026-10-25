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
  if (resetAt != null && resetAt is! int) {
    throw const FormatException('Invalid totals');
  }
  return BackupData(
    global: GlobalState(
      lifetimeTotalTaps: _nonNegative(global['taps']),
      lifetimeTotalSessions: _nonNegative(global['sessions']),
      epoch: _int(global['epoch']),
      lastResetAt: resetAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(resetAt as int),
    ),
    sessions: parsed,
  );
}

Session _session(Map<dynamic, dynamic> raw) {
  final id = raw['id'];
  if (id is! String || id.isEmpty) {
    throw const FormatException('Invalid session');
  }
  final startedAt = _int(raw['startedAt']);
  final endedAt = _int(raw['endedAt']);
  final count = _nonNegative(raw['count']);
  if (count == 0 || endedAt < startedAt) {
    throw const FormatException('Invalid session');
  }
  return Session(
    id: id,
    startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt),
    endedAt: DateTime.fromMillisecondsSinceEpoch(endedAt),
    count: count,
    durationSeconds: _nonNegative(raw['durationSeconds']),
    contributionEpoch: _int(raw['epoch']),
    priceCents: raw['priceCents'] == null
        ? null
        : _nonNegative(raw['priceCents']),
    restaurant: _restaurant(raw['restaurant']),
  );
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

int _nonNegative(Object? value) {
  final number = _int(value);
  if (number < 0) throw const FormatException('Invalid number');
  return number;
}
