import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:celechron/http/spider.dart';
import 'package:celechron/model/option.dart';
import '../format.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'common_ui.dart';

/// Clean Google-style Settings modal dialog (Account, Theme, GPA Privacy, About).
Future<void> showSettingsDialog(BuildContext context, DesktopStore store) =>
    showDialog<void>(
      context: context,
      builder: (context) => _SettingsDialog(store: store),
    );

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog({required this.store});
  final DesktopStore store;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前 ZJUAM 账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.logout();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Dialog(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Text('设置', style: DesktopType.title(context)),
                    const Spacer(),
                    DesktopIconButton(
                      icon: Icons.close_rounded,
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.hairline),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading('账号'),
                      _SettingRow(
                        label: 'ZJUAM 学号',
                        trailing: Text(
                          store.isLoggedIn ? store.username : '未登录',
                          style: DesktopType.body(context, numeric: true),
                        ),
                      ),
                      if (store.isLoggedIn)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DesktopAction(
                            onTap: () => _confirmLogout(context),
                            borderRadius: DesktopRadius.chip,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            child: Text(
                              '退出登录',
                              style: DesktopType.meta(context)
                                  .copyWith(color: c.danger),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Divider(color: c.hairline),
                      const SizedBox(height: 14),
                      const SectionHeading('外观'),
                      _SettingRow(
                        label: '主题模式',
                        trailing: DesktopSegmented<BrightnessMode>(
                          compact: true,
                          items: const {
                            BrightnessMode.light: '浅色',
                            BrightnessMode.dark: '深色',
                            BrightnessMode.system: '跟随系统',
                          },
                          value: store.brightnessMode,
                          onChanged: store.setBrightnessMode,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: c.hairline),
                      const SizedBox(height: 14),
                      const SectionHeading('隐私'),
                      _SettingRow(
                        label: '隐藏绩点与分数',
                        trailing: Switch(
                          value: store.gpaHidden,
                          onChanged: (_) => store.toggleGpaHidden(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: c.hairline),
                      const SizedBox(height: 14),
                      const SectionHeading('关于'),
                      _SettingRow(
                        label: 'Celechron Desktop',
                        trailing: Text('1.3.1',
                            style: DesktopType.meta(context, numeric: true)),
                      ),
                      _SettingRow(
                        label: 'Fuse 版本',
                        trailing: Text(store.fuseVersion,
                            style: DesktopType.meta(context, numeric: true)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DesktopAction(
                          onTap: () => launchUrl(
                            Uri.parse('https://github.com/Celechron/Celechron'),
                            mode: LaunchMode.externalApplication,
                          ),
                          borderRadius: DesktopRadius.chip,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          child: Text(
                            'GitHub 仓库 ↗',
                            style: DesktopType.meta(context)
                                .copyWith(color: c.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.trailing});
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: DesktopType.body(context))),
            trailing,
          ],
        ),
      );
}

/// Sync Health & Module Timestamps dialog triggered from Top Bar Sync chip.
Future<void> showSyncStatusDialog(BuildContext context, DesktopStore store) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final c = DesktopColors.of(context);
            final hasErrors = store.lastErrors.isNotEmpty;
            final hasWarnings = store.lastWarnings.isNotEmpty;
            return SizedBox(
              width: 440,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasErrors
                              ? Icons.cloud_off_rounded
                              : hasWarnings
                                  ? Icons.cloud_queue_rounded
                                  : Icons.cloud_done_outlined,
                          size: 19,
                          color: hasErrors
                              ? c.danger
                              : hasWarnings
                                  ? c.warning
                                  : c.success,
                        ),
                        const SizedBox(width: 8),
                        Text('同步状态', style: DesktopType.title(context)),
                        const Spacer(),
                        DesktopIconButton(
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '精简桌面同步：仅拉取课表、考试、成绩与学在浙大作业（直连校园网优先，自动回退代理）',
                      style: DesktopType.caption(context),
                    ),
                    if (store.moduleStatuses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in store.moduleStatuses)
                            ConcentricTag(
                              label: switch (m.state) {
                                FetchModuleState.success => '${m.label} ✓',
                                FetchModuleState.pending => '${m.label} …',
                                FetchModuleState.failed => '${m.label} !',
                              },
                              foreground: switch (m.state) {
                                FetchModuleState.success => c.success,
                                FetchModuleState.pending => c.primary,
                                FetchModuleState.failed => c.danger,
                              },
                              background: switch (m.state) {
                                FetchModuleState.success => c.successFill,
                                FetchModuleState.pending => c.selectedFill,
                                FetchModuleState.failed => c.dangerFill,
                              },
                              radius: DesktopRadius.tag,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SettingRow(
                      label: '最近一次全量同步',
                      trailing: Text(
                        updatedAgo(store.lastRefreshAt, store.now),
                        style: DesktopType.meta(context, numeric: true),
                      ),
                    ),
                    _SettingRow(
                      label: '学在浙大作业',
                      trailing: Text(
                        updatedAgo(store.homeworkUpdatedAt, store.now),
                        style: DesktopType.meta(context, numeric: true),
                      ),
                    ),
                    _SettingRow(
                      label: '课表与考试',
                      trailing: Text(
                        updatedAgo(store.courseUpdatedAt, store.now),
                        style: DesktopType.meta(context, numeric: true),
                      ),
                    ),
                    _SettingRow(
                      label: '成绩数据',
                      trailing: Text(
                        updatedAgo(store.gradeUpdatedAt, store.now),
                        style: DesktopType.meta(context, numeric: true),
                      ),
                    ),
                    if (hasWarnings) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.warningFill,
                          borderRadius:
                              BorderRadius.circular(DesktopRadius.block),
                        ),
                        child: Text(
                          store.lastWarnings.join('\n'),
                          style: DesktopType.caption(context)
                              .copyWith(color: c.warning),
                        ),
                      ),
                    ],
                    if (hasErrors) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.dangerFill,
                          borderRadius:
                              BorderRadius.circular(DesktopRadius.block),
                        ),
                        child: Text(
                          store.lastErrors.join('\n'),
                          style: DesktopType.caption(context)
                              .copyWith(color: c.danger),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DesktopAction(
                      onTap: (store.isLoggedIn && !store.refreshing)
                          ? () => store.refresh()
                          : null,
                      backgroundColor: c.primary,
                      hoverColor: c.primary.withValues(alpha: 0.9),
                      borderRadius: DesktopRadius.chip,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Center(
                        child: Text(
                          store.refreshing ? '同步中…' : '立即同步全部数据',
                          style: DesktopType.strong(context)
                              .copyWith(color: c.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
