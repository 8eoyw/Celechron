import 'package:flutter/material.dart';

import 'package:celechron/desktop/store.dart';
import 'package:celechron/desktop/theme.dart';
import 'package:celechron/desktop/widgets.dart';

import 'package:celechron/model/option.dart';

/// 设置页：账号（登录/退出/同步）+ 外观（明暗模式）+ 关于（版本与项目链接）。规格见 lib/desktop/DESIGN.md
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final DesktopStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _loginError;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final err = await widget.store.login(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loginError = err);
  }

  Future<void> _doLogout() async {
    await widget.store.logout();
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _doLogout();
              },
              child: const Text('退出')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _accountCard(context)),
            SizedBox(width: DS.s3),
            Expanded(child: _rightColumn(context)),
          ],
        );
      },
    );
  }

  // ─────────────────────── 账号（左） ───────────────────────

  Widget _accountCard(BuildContext context) {
    final store = widget.store;
    if (store.isLoggedIn) {
      return DCard(
        title: '账号',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 32, color: DSColors.of(context).muted),
                SizedBox(width: DS.s2),
                Expanded(
                    child: Text(store.username,
                        style: DText.strong(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: DS.s3),
            Row(
              children: [
                Expanded(
                    child:
                        _actionButton(context, '立即同步', Icons.sync_outlined, () {
                  store.refresh();
                })),
                SizedBox(width: DS.s2),
                Expanded(
                    child: _actionButton(
                        context, '退出登录', Icons.logout, _confirmLogout)),
              ],
            ),
          ],
        ),
      );
    }
    return DCard(
      title: '账号',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('学号', style: DText.muted(context)),
          SizedBox(height: DS.s1),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _userCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          SizedBox(height: DS.s3),
          Text('密码', style: DText.muted(context)),
          SizedBox(height: DS.s1),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          if (_loginError != null)
            Padding(
                padding: const EdgeInsets.only(top: DS.s2),
                child: Text('登录失败：' + _loginError!,
                    style: DText.muted(context).copyWith(color: DS.danger))),
          SizedBox(height: DS.s3),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _doLogin,
              child: const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final colors = DSColors.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          foregroundColor: colors.muted,
          side: BorderSide(color: colors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: DS.s1),
          Text(label, style: DText.body(context)),
        ],
      ),
    );
  }

  // ─────────────────────── 右栏：外观 + 关于 ───────────────────────

  Widget _rightColumn(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _appearanceCard(context)),
        SizedBox(height: DS.s3),
        _aboutCard(context),
      ],
    );
  }

  Widget _appearanceCard(BuildContext context) {
    final mode = widget.store.brightnessMode;
    return DCard(
      title: '外观',
      child: Column(
        children: [
          DRow(
              height: 40,
              selected: mode == BrightnessMode.light,
              onTap: () => widget.store.setBrightnessMode(BrightnessMode.light),
              child: _modeRow(context, BrightnessMode.light, '浅色', mode)),
          DRow(
              height: 40,
              selected: mode == BrightnessMode.dark,
              onTap: () => widget.store.setBrightnessMode(BrightnessMode.dark),
              child: _modeRow(context, BrightnessMode.dark, '深色', mode)),
          DRow(
              height: 40,
              selected: mode == BrightnessMode.system,
              onTap: () =>
                  widget.store.setBrightnessMode(BrightnessMode.system),
              child: _modeRow(context, BrightnessMode.system, '跟随系统', mode)),
        ],
      ),
    );
  }

  Widget _modeRow(BuildContext context, BrightnessMode mode, String label,
      BrightnessMode current) {
    final active = mode == current;
    final primary = Theme.of(context).colorScheme.primary;
    final muted = DSColors.of(context).muted;
    return Row(
      children: [
        Icon(
            mode == BrightnessMode.light
                ? Icons.light_mode
                : mode == BrightnessMode.dark
                    ? Icons.dark_mode
                    : Icons.brightness_6,
            size: 18,
            color: active ? primary : muted),
        SizedBox(width: DS.s2),
        Expanded(
            child: Text(label,
                style: active ? DText.strong(context) : DText.body(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        if (active) Icon(Icons.check_circle, size: 18, color: primary),
      ],
    );
  }

  /// 关于卡：版本号 + 项目链接（遵循 import 规则，链接为样式化文字，不引 url_launcher）
  Widget _aboutCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DCard(
      title: '关于',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Celechron 版本', style: DText.muted(context)),
              SizedBox(width: DS.s2),
              Text(widget.store.fuseVersion, style: DText.strong(context)),
            ],
          ),
          SizedBox(height: DS.s2),
          Text(
            'https://celechron.top',
            style: DText.body(context)
                .copyWith(color: primary, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }
}
