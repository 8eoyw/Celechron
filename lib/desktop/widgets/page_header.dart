import 'package:flutter/material.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'login_form.dart';
import 'skeleton.dart';

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
  Widget build(BuildContext context) => SizedBox(
      height:
          MediaQuery.textScalerOf(context).scale(72).clamp(72, double.infinity),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(children: [
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: display
                          ? PaperType.display(context)
                          : PaperType.h1(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: PaperType.meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ]
                ])),
            ...actions
          ])));
}

class PaperPage extends StatelessWidget {
  const PaperPage(
      {super.key,
      required this.store,
      required this.header,
      required this.child});
  final DesktopStore store;
  final PageHeader header;
  final Widget child;
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
      style: PaperType.body(context),
      child: Column(children: [
        header,
        Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: !store.isLoggedIn
                    ? LoginForm(store: store)
                    : store.initialLoading
                        ? const SkeletonRows()
                        : child))
      ]));
}
