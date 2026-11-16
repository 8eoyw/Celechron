import 'package:flutter/material.dart';

enum DesktopPage {
  today('今天', Icons.today_outlined),
  calendar('日程', Icons.calendar_view_week_outlined),
  homework('作业', Icons.edit_note_outlined),
  exams('考试', Icons.event_note_outlined),
  grades('成绩', Icons.school_outlined),
  tasks('任务', Icons.task_alt_outlined),
  settings('设置', Icons.settings_outlined);

  const DesktopPage(this.label, this.icon);
  final String label;
  final IconData icon;
}
