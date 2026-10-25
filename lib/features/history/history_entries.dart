import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/counter/views/counter_timer.dart';

String formatSessionSeconds(int seconds) =>
    formatSessionDuration(Duration(seconds: seconds));

sealed class HistoryEntry {
  const HistoryEntry();
}

class MonthHeader extends HistoryEntry {
  const MonthHeader(this.month, this.sessions, this.pieces);

  /// First day of the month, local time.
  final DateTime month;
  final int sessions;
  final int pieces;
}

class SessionEntry extends HistoryEntry {
  const SessionEntry(this.session);
  final Session session;
}

/// Sessions (newest first) with a header before each calendar month.
List<HistoryEntry> historyEntries(List<Session> newestFirst) {
  final entries = <HistoryEntry>[];
  var i = 0;
  while (i < newestFirst.length) {
    final ended = newestFirst[i].endedAt.toLocal();
    final month = DateTime(ended.year, ended.month);
    final inMonth = <Session>[];
    while (i < newestFirst.length) {
      final other = newestFirst[i].endedAt.toLocal();
      if (other.year != month.year || other.month != month.month) break;
      inMonth.add(newestFirst[i++]);
    }
    entries
      ..add(
        MonthHeader(
          month,
          inMonth.length,
          inMonth.fold(0, (sum, session) => sum + session.count),
        ),
      )
      ..addAll(inMonth.map(SessionEntry.new));
  }
  return entries;
}
