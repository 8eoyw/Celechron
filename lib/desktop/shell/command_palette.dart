import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/list_row.dart';
import '../widgets/section_label.dart';
import 'navigation.dart';

Future<DesktopPage?> showCommandPalette(
        BuildContext context, DesktopStore store) =>
    showGeneralDialog<DesktopPage>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '关闭搜索',
        barrierColor: const Color(0x66000000),
        transitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (context, animation, secondaryAnimation) =>
            CommandPalette(store: store));

class _Result {
  const _Result(this.group, this.title, this.page, [this.subtitle]);
  final String group, title;
  final String? subtitle;
  final DesktopPage page;
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.store});
  final DesktopStore store;
  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  String query = '';
  int selected = 0;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  List<_Result> get results {
    final all = [
      for (final p in DesktopPage.values) _Result('页面', p.label, p),
      for (final t in widget.store.todos)
        _Result('作业', t.name, DesktopPage.homework, t.course),
      for (final e in [
        for (final s in widget.store.semesters) ...widget.store.examsOf(s)
      ])
        _Result('考试', e.exam.name, DesktopPage.exams)
    ];
    final counts = <String, int>{};
    return all
        .where((r) => '${r.title} ${r.subtitle ?? ''}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .where(
            (r) => counts.update(r.group, (n) => n + 1, ifAbsent: () => 1) <= 8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = results;
    final c = PaperColors.of(context);
    return Align(
        alignment: Alignment.topCenter,
        child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.sizeOf(context).height * .15),
            child: Container(
                width: 560,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .64),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Paper.frameRadius),
                    boxShadow: c.shadow),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(Paper.frameRadius),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Material(
                            color: c.glassSurface,
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        Paper.frameRadius),
                                    border:
                                        Border.all(color: c.hairlineStrong)),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Focus(
                                          onKeyEvent: (_, event) {
                                            if (event is! KeyDownEvent) {
                                              return KeyEventResult.ignored;
                                            }
                                            if (event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .arrowDown ||
                                                event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .arrowUp) {
                                              if (entries.isNotEmpty) {
                                                setState(() => selected =
                                                    (selected +
                                                            (event.logicalKey ==
                                                                    LogicalKeyboardKey
                                                                        .arrowDown
                                                                ? 1
                                                                : -1)) %
                                                        entries.length);
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  if (scroll.hasClients) {
                                                    scroll.animateTo(
                                                        (selected * 54.0).clamp(
                                                            0,
                                                            scroll.position
                                                                .maxScrollExtent),
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    100),
                                                        curve: Curves.easeOut);
                                                  }
                                                });
                                              }
                                              return KeyEventResult.handled;
                                            }
                                            if (event.logicalKey ==
                                                    LogicalKeyboardKey.enter &&
                                                entries.isNotEmpty) {
                                              Navigator.pop(context,
                                                  entries[selected].page);
                                              return KeyEventResult.handled;
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          child: SizedBox(
                                              height: 50,
                                              child: Row(children: [
                                                Expanded(
                                                    child: TextField(
                                                        autofocus: true,
                                                        style: PaperType.body(
                                                            context),
                                                        decoration: InputDecoration(
                                                            hintText:
                                                                '搜索页面、作业、考试',
                                                            filled: false,
                                                            border:
                                                                InputBorder
                                                                    .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        14),
                                                            prefixIcon: Icon(
                                                                Icons
                                                                    .search_rounded,
                                                                size: 18,
                                                                color: c.text2)),
                                                        onChanged: (v) =>
                                                            setState(() {
                                                              query = v;
                                                              selected = 0;
                                                            }))),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 14),
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 7,
                                                                vertical: 2),
                                                        decoration: BoxDecoration(
                                                            color:
                                                                c.glassControl,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        Paper
                                                                            .chipRadius)),
                                                        child: Text('Esc',
                                                            style: PaperType
                                                                    .meta(
                                                                        context)
                                                                .copyWith(
                                                                    fontSize:
                                                                        11,
                                                                    color: c
                                                                        .text3))))
                                              ]))),
                                      const Divider(),
                                      Flexible(
                                          child: ListView(
                                              controller: scroll,
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.all(10),
                                              children: [
                                            if (entries.isEmpty)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  child: Text('没有匹配结果',
                                                      style: PaperType.meta(
                                                          context))),
                                            for (var i = 0;
                                                i < entries.length;
                                                i++) ...[
                                              if (i == 0 ||
                                                  entries[i].group !=
                                                      entries[i - 1].group)
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: SectionLabel(
                                                        entries[i].group)),
                                              PaperAction(
                                                  selected: selected == i,
                                                  borderRadius:
                                                      Paper.smallRadius,
                                                  onTap: () => Navigator.pop(
                                                      context, entries[i].page),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                                  child: Row(children: [
                                                    Icon(entries[i].page.icon,
                                                        size: 17,
                                                        color: selected == i
                                                            ? c.selectionInk
                                                            : c.text2),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                        child: Text(
                                                            entries[i].title,
                                                            style: PaperType
                                                                    .body(
                                                                        context)
                                                                .copyWith(
                                                                    color: selected ==
                                                                            i
                                                                        ? c.selectionInk
                                                                        : null),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                    if (entries[i].subtitle !=
                                                        null)
                                                      ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      150),
                                                          child: Text(
                                                              entries[i]
                                                                  .subtitle!,
                                                              style: PaperType
                                                                  .meta(
                                                                      context),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis))
                                                  ]))
                                            ]
                                          ]))
                                    ]))))))));
  }
}
