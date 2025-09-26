import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:annoying_ledger/features/auth/controllers/auth_controller.dart';
import 'package:annoying_ledger/features/auth/view/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrorIfNeeded() {
    final auth = context.read<AuthController>();
    if (auth.errorMessage != null) {
      auth.clearError();
    }
    if (auth.sessionExpired) {
      auth.acknowledgeSessionExpiry();
    }
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (auth.isAuthenticated) {
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final theme = Theme.of(context);
        final error = auth.errorMessage;
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxFormWidth = _formWidthFor(constraints.maxWidth);
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxFormWidth),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Annoying Ledger 로그인',
                                  style: theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: '이메일',
                                    hintText: 'user@example.com',
                                  ),
                                  validator: (value) {
                                    final trimmed = value?.trim() ?? '';
                                    if (trimmed.isEmpty) {
                                      return '이메일을 입력해 주세요.';
                                    }
                                    if (!trimmed.contains('@')) {
                                      return '올바른 이메일 형식이 아닙니다.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _clearErrorIfNeeded(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: '비밀번호',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').isEmpty) {
                                      return '비밀번호를 입력해 주세요.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _clearErrorIfNeeded(),
                                ),
                                const SizedBox(height: 12),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      error,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => _submit(auth),
                                  child: auth.isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('로그인'),
                                ),
                                TextButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : _navigateToRegister,
                                  child: const Text('회원가입'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  double _formWidthFor(double maxWidth) {
    if (maxWidth >= 1000) {
      return 560;
    }
    if (maxWidth >= 600) {
      return 480;
    }
    return 420;
  }

  Future<void> _navigateToRegister() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    final email = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const RegisterScreen()));

    if (!mounted) return;

    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')));
    }
  }
}
