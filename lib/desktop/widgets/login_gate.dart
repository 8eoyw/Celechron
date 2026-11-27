import 'package:flutter/material.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'common_ui.dart';

/// Clean Google-style ZJUAM sign-in gate shown when the user is logged out.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.store});
  final DesktopStore store;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  late bool _busy = widget.store.loggingIn;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_user.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '请输入学号和密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await widget.store.login(_user.text.trim(), _password.text);
      if (mounted) setState(() => _error = result);
    } on Object {
      if (mounted) setState(() => _error = '登录失败，请检查网络或代理后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DesktopColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: c.sheet,
            borderRadius: BorderRadius.circular(DesktopRadius.sheet),
            border: Border.all(color: c.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(DesktopRadius.block),
                    ),
                    child: Icon(Icons.schedule_rounded,
                        size: 20, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('登录 Celechron', style: DesktopType.title(context)),
                      Text(
                        '使用浙江大学统一身份认证（ZJUAM）',
                        style: DesktopType.caption(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _user,
                style: DesktopType.body(context),
                decoration: const InputDecoration(
                  labelText: '学号',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                ),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                style: DesktopType.body(context),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                ),
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 20),
              DesktopAction(
                onTap: _busy ? null : _submit,
                backgroundColor: _busy ? c.surfaceHigh : c.primary,
                hoverColor: _busy
                    ? c.surfaceHigh
                    : c.primary.withValues(alpha: 0.92),
                borderRadius: DesktopRadius.chip,
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text(
                    _busy ? '登录中…' : '登录',
                    style: DesktopType.strong(context).copyWith(
                      color: _busy ? c.text2 : c.onPrimary,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.dangerFill,
                    borderRadius: BorderRadius.circular(DesktopRadius.block),
                  ),
                  child: Text(
                    _error!,
                    style: DesktopType.meta(context).copyWith(color: c.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
