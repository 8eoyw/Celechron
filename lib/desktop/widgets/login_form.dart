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
  late bool busy = widget.store.loggingIn;
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
  Widget build(BuildContext context) {
    final c = PaperColors.of(context);
    return Center(
        child: Container(
            width: 380,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: c.rail,
                borderRadius: BorderRadius.circular(Paper.blockRadius),
                border: Border.all(color: c.hairline)),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('登录 Celechron', style: PaperType.h1(context)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: user,
                      style: PaperType.body(context),
                      decoration: const InputDecoration(
                          labelText: '学号',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14)),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username]),
                  const SizedBox(height: 14),
                  TextField(
                      controller: password,
                      style: PaperType.body(context),
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: '密码',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14)),
                      onSubmitted: (_) => submit(),
                      autofillHints: const [AutofillHints.password]),
                  const SizedBox(height: 18),
                  Container(
                      decoration: BoxDecoration(
                          color: busy ? c.surfaceElevated : c.text,
                          borderRadius: BorderRadius.circular(10)),
                      child: PaperAction(
                          borderRadius: 10,
                          onTap: busy ? null : submit,
                          padding: const EdgeInsets.all(11),
                          child: Center(
                              child: Text(busy ? '登录中…' : '登录',
                                  style: PaperType.strong(context).copyWith(
                                      color: busy ? c.text2 : c.canvas))))),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error!,
                            style: PaperType.meta(context)
                                .copyWith(color: c.danger)))
                ])));
  }
}
