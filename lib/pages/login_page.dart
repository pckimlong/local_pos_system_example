import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sale_product/helpers/build_context_helper.dart';
import 'package:sale_product/root_page.dart';

const _email = 'admin@gmail.com';
const _password = '123456';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) {
    return Future.delayed(loginTime).then((_) {
      if (data.name != _email) {
        return 'User not exists';
      }
      if (data.password != _password) {
        return 'Password does not match';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterLogin(
      title: 'Yaz Shop',
      onLogin: _authUser,
      onSubmitAnimationCompleted: () {
        context.replaceTo((_) => const RootPage());
      },
      hideForgotPasswordButton: true,
      onRecoverPassword: (_) => throw UnimplementedError(),
      theme: LoginTheme(
        primaryColor: Theme.of(context).primaryColor,
        accentColor: Theme.of(context).colorScheme.secondary,
        errorColor: Colors.red,
        titleStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
