import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/phone_formatter.dart';
import '../widgets/labeled_text_field.dart';

enum AuthMode { login, register }

/// Экран авторизации приложения «Всласть».
///
/// Вход:
///   Телефон + пароль
///
/// Регистрация:
///   Имя
///   Фамилия
///   Телефон
///   E-mail
///   Пароль
///   Повтор пароля
///   Дата рождения
///   Город
///
/// Восстановление:
///   E-mail -> письмо Supabase -> новый пароль
class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  final _loginPhoneController = TextEditingController();

  final _loginPasswordController = TextEditingController();

  bool _obscurePassword = true;

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  final _regPasswordController = TextEditingController();

  final _regPasswordConfirmController = TextEditingController();

  final _firstNameController = TextEditingController();

  final _lastNameController = TextEditingController();

  final _phoneController = TextEditingController(text: '+7 ');

  final _emailController = TextEditingController();

  bool _obscureRegPassword = true;

  bool _obscureRegPasswordConfirm = true;

  DateTime? _birthDate;

  bool _agreedToTerms = false;

  bool _isSubmitting = false;

  late final TapGestureRecognizer _agreementLinkRecognizer;

  String _selectedCity = 'Нижневартовск';

  // ===========================================================================
  // RECOVERY
  // ===========================================================================

  final _recoveryPasswordController = TextEditingController();

  final _recoveryPasswordConfirmController = TextEditingController();

  bool _obscureRecoveryPassword = true;

  bool _obscureRecoveryPasswordConfirm = true;

  @override
  void initState() {
    super.initState();

    _selectedCity = context.read<LocationProvider>().city;

    _agreementLinkRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // TODO:
        // Открыть реальный текст согласия.
      };
  }

  @override
  void dispose() {
    _loginPhoneController.dispose();

    _loginPasswordController.dispose();

    _regPasswordController.dispose();

    _regPasswordConfirmController.dispose();

    _firstNameController.dispose();

    _lastNameController.dispose();

    _phoneController.dispose();

    _emailController.dispose();

    _recoveryPasswordController.dispose();

    _recoveryPasswordConfirmController.dispose();

    _agreementLinkRecognizer.dispose();

    super.dispose();
  }

  // ===========================================================================
  // CITY
  // ===========================================================================

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LocationProvider.availableCities
                .map(
                  (city) => ListTile(
                    title: Text(city, style: AppTextStyles.rowLabel),
                    trailing: city == _selectedCity
                        ? const Icon(Icons.check, color: AppColors.primaryBrown)
                        : null,
                    onTap: () {
                      Navigator.pop(context, city);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (picked != null) {
      setState(() {
        _selectedCity = picked;
      });
    }
  }

  // ===========================================================================
  // BIRTH DATE
  // ===========================================================================

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 6, now.month, now.day),
    );

    if (!mounted) {
      return;
    }

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _submitLogin() async {
    if (_isSubmitting) {
      return;
    }

    final phone = _loginPhoneController.text.trim();

    final password = _loginPasswordController.text;

    if (phone.isEmpty) {
      _showMessage('Введите номер телефона.');
      return;
    }

    final normalizedPhone = AuthProvider.normalizePhone(phone);

    if (!_isValidRussianPhone(normalizedPhone)) {
      _showMessage('Введите корректный номер телефона.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Введите пароль.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();

    final success = await auth.signInWithPhone(
      phone: normalizedPhone,
      password: password,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      context.read<LocationProvider>().setCity(
        auth.city.isNotEmpty ? auth.city : _selectedCity,
      );

      // После успешного входа AuthScreen был открыт через
      // SplashScreen.pushReplacement(), поэтому под ним нет
      // предыдущего экрана. maybePop() здесь ничего не делает.
      //
      // Переходим напрямую в нужный режим и очищаем navigation stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );

      return;
    }

    final message = auth.errorMessage;

    if (message != null && message.isNotEmpty) {
      _showMessage(message);
    }
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  Future<void> _submitRegister() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    // -------------------------------------------------------------------------
    // CONSENT
    // -------------------------------------------------------------------------

    if (!_agreedToTerms) {
      _showMessage('Подтвердите согласие на обработку персональных данных.');

      return;
    }

    // -------------------------------------------------------------------------
    // VALUES
    // -------------------------------------------------------------------------

    final firstName = _firstNameController.text.trim();

    final lastName = _lastNameController.text.trim();

    final phone = _phoneController.text.trim();

    final normalizedPhone = AuthProvider.normalizePhone(phone);

    final email = _emailController.text.trim().toLowerCase();

    final password = _regPasswordController.text;

    final passwordConfirm = _regPasswordConfirmController.text;

    // -------------------------------------------------------------------------
    // NAME
    // -------------------------------------------------------------------------

    if (firstName.isEmpty) {
      _showMessage('Введите имя.');
      return;
    }

    // -------------------------------------------------------------------------
    // PHONE
    // -------------------------------------------------------------------------

    if (!_isValidRussianPhone(normalizedPhone)) {
      _showMessage('Введите корректный номер телефона.');

      return;
    }

    // -------------------------------------------------------------------------
    // EMAIL
    // -------------------------------------------------------------------------

    if (email.isEmpty) {
      _showMessage('Введите e-mail для восстановления пароля.');

      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Введите корректный e-mail.');

      return;
    }

    // -------------------------------------------------------------------------
    // PASSWORD
    // -------------------------------------------------------------------------

    if (password.length < 6) {
      _showMessage('Пароль должен содержать минимум 6 символов.');

      return;
    }

    if (password != passwordConfirm) {
      _showMessage('Пароли не совпадают.');

      return;
    }

    // -------------------------------------------------------------------------
    // SUPABASE
    // -------------------------------------------------------------------------

    setState(() {
      _isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();

    final success = await auth.signUp(
      phone: normalizedPhone,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      displayName: _buildDisplayName(firstName, lastName),
      city: _selectedCity,
      birthDate: _birthDate,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    // -------------------------------------------------------------------------
    // SUCCESS
    // -------------------------------------------------------------------------

    if (success) {
      final message = auth.errorMessage;

      // Если Supabase требует подтверждение e-mail.
      if (!auth.isLoggedIn) {
        _showMessage(message ?? 'Регистрация выполнена. Проверьте e-mail.');

        setState(() {
          _mode = AuthMode.login;

          _loginPhoneController.text = _formatPhoneForDisplay(normalizedPhone);
        });

        return;
      }

      context.read<LocationProvider>().setCity(_selectedCity);

      Navigator.of(context).maybePop();

      return;
    }

    // -------------------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------------------

    final message = auth.errorMessage;

    if (message != null && message.isNotEmpty) {
      _showMessage(message);
    } else {
      _showMessage('Не удалось зарегистрировать пользователя.');
    }
  }

  // ===========================================================================
  // PASSWORD RESET REQUEST
  // ===========================================================================

  Future<void> _resetPassword() async {
    final controller = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Восстановление пароля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Введите e-mail, который указан '
                'в вашем аккаунте.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted) {
      return;
    }

    if (email == null || email.isEmpty) {
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Введите корректный e-mail.');

      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.resetPassword(email);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('Письмо для восстановления пароля отправлено на $email.');

      return;
    }

    _showMessage(auth.errorMessage ?? 'Не удалось отправить письмо.');
  }

  // ===========================================================================
  // RECOVERY
  // ===========================================================================

  Future<void> _submitNewPassword() async {
    if (_isSubmitting) {
      return;
    }

    final password = _recoveryPasswordController.text;

    final passwordConfirm = _recoveryPasswordConfirmController.text;

    if (password.length < 6) {
      _showMessage('Пароль должен содержать минимум 6 символов.');

      return;
    }

    if (password != passwordConfirm) {
      _showMessage('Пароли не совпадают.');

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();

    final success = await auth.updatePassword(password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _recoveryPasswordController.clear();

      _recoveryPasswordConfirmController.clear();

      _showMessage('Пароль успешно изменён.');

      auth.clearPasswordRecovery();

      setState(() {
        _mode = AuthMode.login;
      });

      return;
    }

    _showMessage(auth.errorMessage ?? 'Не удалось изменить пароль.');
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool _isValidRussianPhone(String phone) {
    return RegExp(r'^\+7\d{10}$').hasMatch(phone);
  }

  static String _buildDisplayName(String firstName, String lastName) {
    return <String>[
      firstName.trim(),
      lastName.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  static String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11) {
      return phone;
    }

    return '+7 '
        '(${digits.substring(1, 4)}) '
        '${digits.substring(4, 7)}-'
        '${digits.substring(7, 9)}-'
        '${digits.substring(9, 11)}';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isRecovery = auth.isPasswordRecovery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------------
              // CLOSE
              // -----------------------------------------------------------------
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -----------------------------------------------------------------
              // LOGO
              // -----------------------------------------------------------------
              Image.asset(
                'assets/images/logo_light.png',
                width: double.infinity,
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              if (isRecovery)
                _buildRecoveryForm()
              else ...[
                // ---------------------------------------------------------------
                // MODE SWITCH
                // ---------------------------------------------------------------
                _ModeSwitch(
                  mode: _mode,
                  onChanged: (mode) {
                    if (_isSubmitting) {
                      return;
                    }

                    setState(() {
                      _mode = mode;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  _mode == AuthMode.login
                      ? 'Добро пожаловать!'
                      : 'Создайте аккаунт',
                  style: AppTextStyles.authHeading,
                ),

                const SizedBox(height: 6),

                Text(
                  _mode == AuthMode.login
                      ? 'Войдите, чтобы делать покупки быстрее и удобнее'
                      : 'Заполните данные, чтобы зарегистрироваться и делать покупки во Всласть',
                  style: AppTextStyles.rowLabelMuted,
                ),

                const SizedBox(height: 22),

                if (_mode == AuthMode.login)
                  _buildLoginForm()
                else
                  _buildRegisterForm(),

                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    _mode == AuthMode.login
                        ? 'assets/images/hero_banner.jpg'
                        : 'assets/images/cake_crown_bordeaux.jpg',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOGIN FORM
  // ===========================================================================

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Телефон',
          hint: '+7 (___) ___-__-__',
          leadingIcon: Icons.phone_outlined,
          controller: _loginPhoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [RuPhoneInputFormatter()],
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'Пароль',
          hint: 'Введите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          controller: _loginPasswordController,
          trailing: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
          ),
        ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _isSubmitting ? null : _resetPassword,
            behavior: HitTestBehavior.opaque,
            child: Text('Забыли пароль?', style: AppTextStyles.linkText),
          ),
        ),

        const SizedBox(height: 12),

        _TappableField(
          label: 'Ваш город',
          value: _selectedCity,
          hint: 'Выберите город',
          icon: Icons.location_on_outlined,
          onTap: _isSubmitting ? () {} : _pickCity,
          helperText: 'От выбора города зависит ассортимент и условия доставки',
        ),

        const SizedBox(height: 24),

        _GradientButton(
          label: _isSubmitting ? 'Выполняется вход...' : 'Иду за покупками',
          onTap: _isSubmitting ? () {} : _submitLogin,
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('или', style: AppTextStyles.rowLabelMuted),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _mode = AuthMode.register;
                    });
                  },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryBrown, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Регистрация нового пользователя',
                style: AppTextStyles.rowLabel.copyWith(
                  color: AppColors.primaryBrown,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // REGISTER FORM
  // ===========================================================================

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'Имя',
                hint: 'Введите имя',
                leadingIcon: Icons.person_outline,
                controller: _firstNameController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledTextField(
                label: 'Фамилия',
                hint: 'Введите фамилию',
                leadingIcon: Icons.person_outline,
                controller: _lastNameController,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'Телефон *',
          hint: '+7 (___) ___-__-__',
          leadingIcon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [RuPhoneInputFormatter()],
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'E-mail *',
          hint: 'Введите e-mail',
          leadingIcon: Icons.mail_outline,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 8),

        Text(
          'E-mail нужен для восстановления пароля',
          style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11),
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'Пароль *',
          hint: 'Придумайте пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPassword,
          controller: _regPasswordController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _obscureRegPassword = !_obscureRegPassword;
                    });
                  },
          ),
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'Повторите пароль *',
          hint: 'Повторите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRegPasswordConfirm,
          controller: _regPasswordConfirmController,
          trailing: IconButton(
            icon: Icon(
              _obscureRegPasswordConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _obscureRegPasswordConfirm = !_obscureRegPasswordConfirm;
                    });
                  },
          ),
        ),

        const SizedBox(height: 16),

        _TappableField(
          label: 'Дата рождения',
          value: _birthDate == null ? '' : formatRuDateWithYear(_birthDate!),
          hint: 'Выберите дату',
          icon: Icons.calendar_today_outlined,
          onTap: _isSubmitting ? () {} : _pickBirthDate,
        ),

        const SizedBox(height: 16),

        _TappableField(
          label: 'Ваш город',
          value: _selectedCity,
          hint: 'Выберите город',
          icon: Icons.location_on_outlined,
          onTap: _isSubmitting ? () {} : _pickCity,
          helperText: 'От выбора города зависит ассортимент и условия доставки',
        ),

        const SizedBox(height: 18),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
              activeColor: AppColors.primaryBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.checkboxText,
                    children: [
                      const TextSpan(
                        text:
                            'Я соглашаюсь на обработку персональных данных '
                            'и принимаю условия ',
                      ),
                      TextSpan(
                        text: 'Согласия',
                        style: AppTextStyles.linkText.copyWith(fontSize: 12),
                        recognizer: _agreementLinkRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        _GradientButton(
          label: _isSubmitting ? 'Создаём аккаунт...' : 'Зарегистрироваться',
          onTap: _isSubmitting ? () {} : _submitRegister,
        ),
      ],
    );
  }

  // ===========================================================================
  // PASSWORD RECOVERY FORM
  // ===========================================================================

  Widget _buildRecoveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Новый пароль', style: AppTextStyles.authHeading),

        const SizedBox(height: 8),

        Text(
          'Введите новый пароль для вашего аккаунта.',
          style: AppTextStyles.rowLabelMuted,
        ),

        const SizedBox(height: 24),

        LabeledTextField(
          label: 'Новый пароль',
          hint: 'Введите новый пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRecoveryPassword,
          controller: _recoveryPasswordController,
          trailing: IconButton(
            icon: Icon(
              _obscureRecoveryPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _obscureRecoveryPassword = !_obscureRecoveryPassword;
                    });
                  },
          ),
        ),

        const SizedBox(height: 16),

        LabeledTextField(
          label: 'Повторите новый пароль',
          hint: 'Повторите пароль',
          leadingIcon: Icons.lock_outline,
          obscureText: _obscureRecoveryPasswordConfirm,
          controller: _recoveryPasswordConfirmController,
          trailing: IconButton(
            icon: Icon(
              _obscureRecoveryPasswordConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _obscureRecoveryPasswordConfirm =
                          !_obscureRecoveryPasswordConfirm;
                    });
                  },
          ),
        ),

        const SizedBox(height: 24),

        _GradientButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Сохранить новый пароль',
          onTap: _isSubmitting ? () {} : _submitNewPassword,
        ),
      ],
    );
  }
}

// =============================================================================
// MODE SWITCH
// =============================================================================

class _ModeSwitch extends StatelessWidget {
  final AuthMode mode;

  final ValueChanged<AuthMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _tab(context, 'Вход', AuthMode.login)),
          Expanded(child: _tab(context, 'Регистрация', AuthMode.register)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, AuthMode value) {
    final selected = mode == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.categoryChip.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAPPABLE FIELD
// =============================================================================

class _TappableField extends StatelessWidget {
  final String label;

  final String value;

  final String hint;

  final IconData icon;

  final VoidCallback onTap;

  final String? helperText;

  const _TappableField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.rowLabel),

        const SizedBox(height: 7),

        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryBrown),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    style: hasValue
                        ? AppTextStyles.rowLabel
                        : AppTextStyles.rowLabelMuted,
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AppTextStyles.rowLabelMuted.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// GRADIENT BUTTON
// =============================================================================

class _GradientButton extends StatelessWidget {
  final String label;

  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryBrown,
                AppColors.primaryBrown.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBrown.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.rowLabel.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
