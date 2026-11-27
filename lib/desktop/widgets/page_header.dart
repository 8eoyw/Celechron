import 'package:flutter/material.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'login_form.dart';
import 'skeleton.dart';

/// Unified 46px Antigravity-style top header strip sitting directly on the
/// outer window chrome, above the inset rounded workspace canvas.
class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.actions = const [],
      this.display = false});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool display;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    final h = MediaQuery.textScalerOf(context)
        .scale(Paper.topBarHeight)
        .clamp(Paper.topBarHeight, double.infinity);
    return SizedBox(
        height: h,
        child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                  child: Row(children: [
                Flexible(
                    child: Text(title,
                        style: display
                            ? PaperType.display(context)
                            : PaperType.h1(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(subtitle!,
                          style: PaperType.meta(context)
                              .copyWith(color: c.text3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis))
                ]
              ])),
              if (actions.isNotEmpty) const SizedBox(width: 12),
              ...actions
            ])));
  }
}

/// True Antigravity workspace shell:
/// - Top: sleek 46px header strip on the outer chrome (`c.sidebar`).
/// - Body: ONE single inset rounded workspace canvas (`c.canvas`, 12px radius,
///   whisper hairline) — zero nested card-in-card clutter.
class PaperPage extends StatelessWidget {
  const PaperPage(
      {super.key,
      required this.store,
      required this.header,
      required this.child,
      this.padding = EdgeInsets.zero});
  final DesktopStore store;
  final PageHeader header;
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    return DefaultTextStyle.merge(
        style: PaperType.body(context),
        child: Column(children: [
          header,
          Expanded(
              child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 10, 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: c.canvas,
                      borderRadius: BorderRadius.circular(Paper.frameRadius),
                      border: Border.all(color: c.hairline)),
                  child: !store.isLoggedIn
                      ? LoginForm(store: store)
                      : store.initialLoading
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: SkeletonRows())
                          : Padding(padding: padding, child: child)))
        ]));
  }
}
