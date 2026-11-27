import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:celechron/model/period.dart';
import 'package:celechron/model/semester.dart';

/// Immutable, single-source-of-truth metrics for the strictly time-proportional
/// schedule grid. Every pixel offset and block height derives from [pxPerMin].
@immutable
class TimeGridMetrics {
  const TimeGridMetrics({
    required this.startMinute,
    required this.endMinute,
    required this.pxPerMin,
    this.blockGap = 2.0,
  });

  /// Inclusive visible start minute from midnight (e.g. 450 = 07:30).
  final int startMinute;

  /// Inclusive visible end minute from midnight (e.g. 1350 = 22:30).
  final int endMinute;

  /// Constant linear scale in logical pixels per minute.
  final double pxPerMin;

  /// Inter-block breathing gap subtracted from rendered height.
  final double blockGap;

  int get totalMinutes => endMinute - startMinute;
  double get totalHeight => totalMinutes * pxPerMin;

  double minuteToY(double minute) => (minute - startMinute) * pxPerMin;

  double timeToY(DateTime t, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final mins = t.difference(dayStart).inSeconds / 60.0;
    return minuteToY(mins);
  }

  double yToMinute(double y) => startMinute + (y / pxPerMin);

  double durationHeight(Duration d) {
    final mins = d.inSeconds / 60.0;
    return math.max(18.0, mins * pxPerMin - blockGap);
  }

  /// Compute a consistent linear scale across Day, Today+Tomorrow, and Week
  /// so a 95-minute course always has the exact same visual height on every day.
  factory TimeGridMetrics.forPeriods(
    List<Period> periods, {
    DateTime? now,
    double pxPerMin = 0.96,
  }) {
    var startMin = 8 * 60; // 08:00
    var endMin = 22 * 60; // 22:00
    for (final p in periods) {
      final s = p.startTime.hour * 60 + p.startTime.minute;
      final e = p.endTime.hour * 60 + p.endTime.minute;
      if (s < startMin) startMin = (s ~/ 60) * 60;
      if (e > endMin) endMin = math.min(24 * 60, ((e + 59) ~/ 60) * 60);
    }
    if (now != null) {
      final n = now.hour * 60 + now.minute;
      if (n < startMin) startMin = math.max(0, (n ~/ 60) * 60);
      if (n > endMin) endMin = math.min(24 * 60, ((n + 59) ~/ 60) * 60);
    }
    startMin = math.max(0, startMin - 30);
    endMin = math.min(24 * 60, endMin + 30);
    // Snap to half-hour boundaries for clean gridlines.
    startMin = (startMin ~/ 30) * 30;
    endMin = ((endMin + 29) ~/ 30) * 30;
    return TimeGridMetrics(
      startMinute: startMin,
      endMinute: math.max(startMin + 60, endMin),
      pxPerMin: pxPerMin,
    );
  }
}

@immutable
class PlacedPeriod {
  const PlacedPeriod({
    required this.period,
    required this.column,
    required this.columnCount,
  });

  final Period period;
  final int column;
  final int columnCount;
}

/// Greedy interval-packing layout for overlapping periods on a single day.
List<PlacedPeriod> packPeriods(List<Period> input) {
  if (input.isEmpty) return const [];
  final sorted = List<Period>.of(input)
    ..sort((a, b) {
      final c = a.startTime.compareTo(b.startTime);
      if (c != 0) return c;
      return b.endTime.compareTo(a.endTime);
    });

  // Partition into overlap clusters so non-overlapping items get full width.
  final result = <PlacedPeriod>[];
  var cluster = <Period>[];
  DateTime? clusterEnd;

  void flushCluster() {
    if (cluster.isEmpty) return;
    final colEnds = <DateTime>[];
    final assigned = <(Period, int)>[];
    for (final p in cluster) {
      var placedCol = -1;
      for (var c = 0; c < colEnds.length; c++) {
        if (!colEnds[c].isAfter(p.startTime)) {
          placedCol = c;
          colEnds[c] = p.endTime;
          break;
        }
      }
      if (placedCol == -1) {
        placedCol = colEnds.length;
        colEnds.add(p.endTime);
      }
      assigned.add((p, placedCol));
    }
    final count = colEnds.length;
    for (final (p, col) in assigned) {
      result.add(PlacedPeriod(period: p, column: col, columnCount: count));
    }
    cluster = <Period>[];
    clusterEnd = null;
  }

  for (final p in sorted) {
    if (cluster.isEmpty) {
      cluster.add(p);
      clusterEnd = p.endTime;
    } else if (p.startTime.isBefore(clusterEnd!)) {
      cluster.add(p);
      if (p.endTime.isAfter(clusterEnd!)) clusterEnd = p.endTime;
    } else {
      flushCluster();
      cluster.add(p);
      clusterEnd = p.endTime;
    }
  }
  flushCluster();
  return result;
}

@immutable
class ZjuPeriodMarker {
  const ZjuPeriodMarker({
    required this.index,
    required this.startMinute,
    required this.endMinute,
  });

  final int index;
  final int startMinute;
  final int endMinute;
}

/// Extract ZJU Period 1–13 markers directly from the semester's real calendar
/// table so non-uniform breaks (lunch, dinner, 15/20-min breaks) are exact.
List<ZjuPeriodMarker> zjuPeriodMarkersOf(Semester? semester) {
  final table = semester?.sessionToTime;
  final markers = <ZjuPeriodMarker>[];
  if (table != null && table.length > 1) {
    for (var i = 1; i < table.length; i++) {
      final slot = table[i];
      if (slot.length < 2) continue;
      markers.add(ZjuPeriodMarker(
        index: i,
        startMinute: slot.first.inMinutes,
        endMinute: slot.last.inMinutes,
      ));
    }
  }
  if (markers.isNotEmpty) return markers;
  // Fallback ZJU Zijingang standard period table when calendar is absent.
  const fallbackStarts = [
    480, 530, 595, 645, 695, 805, 855, 905, 970, 1020, 1110, 1160, 1210,
  ];
  return [
    for (var i = 0; i < fallbackStarts.length; i++)
      ZjuPeriodMarker(
        index: i + 1,
        startMinute: fallbackStarts[i],
        endMinute: fallbackStarts[i] + 45,
      ),
  ];
}

@immutable
class FreeGap {
  const FreeGap({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);
}

/// Detect meaningful daytime free gaps (>= 90 min) between scheduled blocks
/// for the inline `+ 规划` affordance on the Day view.
List<FreeGap> findFreeGaps(DateTime day, List<Period> periods) {
  final d = DateTime(day.year, day.month, day.day);
  final windowStart = d.add(const Duration(hours: 8));
  final windowEnd = d.add(const Duration(hours: 21, minutes: 30));
  if (periods.isEmpty) return const [];

  final sorted = List<Period>.of(periods)
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  final merged = <(DateTime, DateTime)>[];
  for (final p in sorted) {
    final s = p.startTime.isBefore(windowStart) ? windowStart : p.startTime;
    final e = p.endTime.isAfter(windowEnd) ? windowEnd : p.endTime;
    if (!e.isAfter(s)) continue;
    if (merged.isEmpty || s.isAfter(merged.last.$2)) {
      merged.add((s, e));
    } else if (e.isAfter(merged.last.$2)) {
      merged[merged.length - 1] = (merged.last.$1, e);
    }
  }

  final gaps = <FreeGap>[];
  var cursor = windowStart;
  for (final (s, e) in merged) {
    if (s.difference(cursor).inMinutes >= 90) {
      gaps.add(FreeGap(start: cursor, end: s));
    }
    if (e.isAfter(cursor)) cursor = e;
  }
  if (windowEnd.difference(cursor).inMinutes >= 120) {
    gaps.add(FreeGap(start: cursor, end: windowEnd));
  }
  return gaps;
}
