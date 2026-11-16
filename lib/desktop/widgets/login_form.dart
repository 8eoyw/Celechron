import 'package:flutter/material.dart';
import '../store.dart';
import '../theme/tokens.dart';
import 'list_row.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.store});
  final DesktopStore store;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final user = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (user.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = '请输入学号和密码');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.store.login(user.text.trim(), password.text);
      if (mounted) setState(() => error = result);
    } on Object {
      if (mounted) setState(() => error = '登录失败，请重试');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
      child: SizedBox(
          width: 360,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('登录 Celechron', style: PaperType.h1(context)),
                const SizedBox(height: 24),
                TextField(
                    controller: user,
                    decoration: const InputDecoration(labelText: '学号'),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username]),
                const SizedBox(height: 16),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '密码'),
                    onSubmitted: (_) => submit(),
                    autofillHints: const [AutofillHints.password]),
                const SizedBox(height: 16),
                PaperAction(
                    selected: true,
                    onTap: busy ? null : submit,
                    padding: const EdgeInsets.all(10),
                    child: Center(
                        child: Text(busy ? '登录中…' : '登录',
                            style: PaperType.strong(context)))),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!,
                          style: PaperType.meta(context)
                              .copyWith(color: PaperColors.of(context).danger)))
              ])));
}
