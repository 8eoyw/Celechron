import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/option.dart';
import '../store.dart';
import '../theme/tokens.dart';
import '../widgets/list_row.dart';
import '../widgets/page_header.dart';
import '../widgets/section_label.dart';
import '../widgets/segmented_control.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final DesktopStore store;
  Future<void> _logout(BuildContext context) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                contentPadding: const EdgeInsets.all(24),
                title: const Text('退出登录'),
                content: const Text('确定要退出当前账号吗？'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('退出登录'))
                ]));
    if (result == true) await store.logout();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => PaperPage(
          store: store,
          header: const PageHeader(title: '设置'),
          child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SectionLabel('账号'),
                        _row(
                            context,
                            '学号',
                            Text(store.username,
                                style: PaperType.body(context))),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: PaperAction(
                                onTap: () => _logout(context),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text('退出登录',
                                    style: PaperType.meta(context).copyWith(
                                        color:
                                            PaperColors.of(context).danger)))),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const SectionLabel('外观'),
                        _row(
                            context,
                            '主题',
                            PaperSegmented(
                                values: const {
                                  BrightnessMode.light: '浅色',
                                  BrightnessMode.dark: '深色',
                                  BrightnessMode.system: '跟随系统'
                                },
                                value: store.brightnessMode,
                                onChanged: store.setBrightnessMode)),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const SectionLabel('成绩'),
                        _row(
                            context,
                            '首页隐藏 GPA',
                            PaperAction(
                                onTap: store.toggleGpaHidden,
                                tooltip: '首页隐藏 GPA',
                                child: SizedBox(
                                    height: 32,
                                    width: 48,
                                    child: ExcludeFocus(
                                        child: Switch(
                                            value: store.gpaHidden,
                                            onChanged: (_) =>
                                                store.toggleGpaHidden()))))),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const SectionLabel('关于'),
                        _row(context, 'Celechron',
                            Text('1.3.1', style: PaperType.meta(context))),
                        _row(
                            context,
                            'Fuse',
                            Text(store.fuseVersion,
                                style: PaperType.meta(context))),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: PaperAction(
                                onTap: () => launchUrl(
                                    Uri.parse(
                                        'https://github.com/Celechron/Celechron'),
                                    mode: LaunchMode.externalApplication),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text('GitHub ↗',
                                    style: PaperType.meta(context).copyWith(
                                        color:
                                            PaperColors.of(context).accent))))
                      ])))));
  Widget _row(BuildContext context, String label, Widget trailing) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: PaperType.body(context))),
        trailing
      ]));
}
