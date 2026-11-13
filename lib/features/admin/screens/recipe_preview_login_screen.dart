import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_recipe_tech_screen.dart';

class RecipePreviewLoginScreen extends StatefulWidget {
  const RecipePreviewLoginScreen({super.key});

  @override
  State<RecipePreviewLoginScreen> createState() =>
      _RecipePreviewLoginScreenState();
}

class _RecipePreviewLoginScreenState extends State<RecipePreviewLoginScreen> {
  static const _background = Color(0xFFF8F4EE);
  static const _brown = Color(0xFF8B5E3C);
  static const _dark = Color(0xFF3B281F);

  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_db.auth.currentSession != null) {
        _openRecipeScreen();
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _runAuth({required bool signUp}) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      setState(() => _message = 'Введите корректный email и пароль не короче 6 символов.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (signUp) {
        final response = await _db.auth.signUp(email: email, password: password);
        if (response.session == null) {
          setState(() => _message =
              'Аккаунт создан. Подтвердите email по письму, затем войдите здесь. В тестовой базе первый зарегистрированный пользователь получает роль владельца.');
          return;
        }
      } else {
        await _db.auth.signInWithPassword(email: email, password: password);
      }
      await _openRecipeScreen();
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (e) {
      if (mounted) setState(() => _message = 'Не удалось войти: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRecipeScreen() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;
      final profile = await _db
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = profile?['role']?.toString();
      if (!['owner', 'admin', 'manager', 'baker', 'pastry_chef', 'pastryChef']
          .contains(role)) {
        if (mounted) {
          setState(() => _message =
              'У этой учётной записи нет доступа к тестированию ТТК. Используйте первый аккаунт, зарегистрированный в тестовом проекте.');
        }
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminRecipeTechScreen()),
      );
    } catch (e) {
      if (mounted) setState(() => _message = 'Не удалось проверить профиль: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFEADFD5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.science_outlined, size: 42, color: _brown),
                      const SizedBox(height: 14),
                      const Text(
                        'Всласть · Тест ТТК',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _dark,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Отдельная тестовая среда. Данные рабочего приложения здесь не используются.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF806F65), height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email для тестового аккаунта',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль (минимум 6 символов)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Text(_message!, style: const TextStyle(color: _brown)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : () => _runAuth(signUp: false),
                        style: FilledButton.styleFrom(
                          backgroundColor: _brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_busy ? 'Подождите…' : 'Войти'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _runAuth(signUp: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brown,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Создать тестовый аккаунт'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
