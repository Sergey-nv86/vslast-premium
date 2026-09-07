import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

enum AuthMode { login, register }

/// Авторизация «Всласть».
///
/// Новый клиент получает постоянный ID вида C-000123.
/// ID генерируется сервером автоматически и используется как логин.
/// Телефон и e-mail на этапе регистрации не запрашиваются.
class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  final _clientIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _clientIdController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_isSubmitting) return;

    final clientId = _clientIdController.text.trim().toUpperCase();
    final password = _passwordController.text;

    if (!RegExp(r'^C-\d{6}$').hasMatch(clientId)) {
      _showMessage('Введите ID клиента, например C-000123.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Введите пароль.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithClientId(
      clientId: clientId,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      _showMessage(auth.errorMessage ?? 'Не удалось выполнить вход.');
      return;
    }

    context.read<LocationProvider>().setCity(
      auth.city.isNotEmpty ? auth.city : 'Нижневартовск',
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _submitRegister() async {
    if (_isSubmitting) return;

    final password = _passwordController.text;
    final confirmation = _passwordConfirmController.text;

    if (password.length < 6) {
      _showMessage('Пароль должен содержать минимум 6 символов.');
      return;
    }

    if (password != confirmation) {
      _showMessage('Пароли не совпадают.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(password: password);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      _showMessage(auth.errorMessage ?? 'Не удалось зарегистрировать клиента.');
      return;
    }

    final newClientId = auth.clientId;
    context.read<LocationProvider>().setCity(
      auth.city.isNotEmpty ? auth.city : 'Нижневартовск',
    );

    await _showRegistrationResult(newClientId);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _showRegistrationResult(String clientId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Регистрация завершена'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ваш постоянный ID клиента:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              SelectableText(
                clientId,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Сохраните этот ID. Он используется для входа в приложение. '
                'Пароль также сохраните в надёжном месте.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Продолжить'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_cafe_outlined,
                    size: 56,
                    color: AppColors.primaryBrown,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Всласть Premium',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mode == AuthMode.login
                        ? 'Вход по ID клиента'
                        : 'Регистрация нового клиента',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<AuthMode>(
                    segments: const [
                      ButtonSegment(
                        value: AuthMode.login,
                        label: Text('Войти'),
                        icon: Icon(Icons.login),
                      ),
                      ButtonSegment(
                        value: AuthMode.register,
                        label: Text('Регистрация'),
                        icon: Icon(Icons.person_add_alt_1),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _mode = selection.first;
                        _passwordController.clear();
                        _passwordConfirmController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_mode == AuthMode.login)
                    _buildLogin()
                  else
                    _buildRegister(),
                  if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        auth.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (_isSubmitting || auth.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _clientIdController,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ID клиента',
            hintText: 'C-000123',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitLogin(),
          decoration: InputDecoration(
            labelText: 'Пароль',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitLogin,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Войти'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Забытый ID или пароль пока нельзя восстановить автоматически. '
          'Сохраняйте их после регистрации.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryBrown),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ID клиента будет создан автоматически после регистрации. '
                  'Телефон и e-mail вводить не нужно.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Пароль',
            helperText: 'Минимум 6 символов',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordConfirmController,
          obscureText: _obscurePasswordConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitRegister(),
          decoration: InputDecoration(
            labelText: 'Повторите пароль',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
              ),
              icon: Icon(
                _obscurePasswordConfirm
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitRegister,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Зарегистрироваться'),
          ),
        ),
      ],
    );
  }
}
