String two(int n) => n.toString().padLeft(2, '0');
String fmtTime(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
String fmtRange(DateTime a, DateTime b) => '${fmtTime(a)}–${fmtTime(b)}';
String weekdayName(int day) => '周${'一二三四五六日'[day - 1]}';
String fmtDate(DateTime t) => '${t.month}/${t.day} ${weekdayName(t.weekday)}';
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
String fmtDeadline(DateTime t, DateTime now) =>
    '${weekdayName(t.weekday)} ${t.year != now.year ? '${t.year}/' : ''}${t.month}/${t.day} ${fmtTime(t)}';
String dayGroup(DateTime t, DateTime now) =>
    switch (calendarDaysBetween(now, t)) {
      0 => '今天',
      1 => '明天',
      _ => '${weekdayName(t.weekday)} ${t.month}/${t.day}',
    };
String fmtDeadlineCountdown(DateTime t, DateTime now) {
  final d = t.difference(now);
  if (d.isNegative) {
    final days = calendarDaysBetween(t, now);
    return '已逾期 ${days > 0 ? '$days 天' : d.abs().inHours > 0 ? '${d.abs().inHours} 小时' : '${d.abs().inMinutes} 分钟'}';
  }
  if (d.inHours < 24) {
    return d.inHours > 0 ? '${d.inHours} 小时' : '${d.inMinutes} 分钟';
  }
  return '${calendarDaysBetween(now, t)} 天';
}

String examCountdown(DateTime t, DateTime now) =>
    switch (calendarDaysBetween(now, t)) {
      0 => '今天',
      1 => '明天',
      final n => '$n 天',
    };
String updatedAgo(DateTime? t, DateTime now) {
  if (t == null) return '尚未同步';
  final minutes = now.difference(t).inMinutes;
  return minutes < 1 ? '刚刚' : '$minutes 分钟前';
}
