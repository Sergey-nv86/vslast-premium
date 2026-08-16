import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

enum _OtpChannel { telegram, max, sms }

extension on _OtpChannel {
  String get label => switch (this) {
    _OtpChannel.telegram => 'Telegram',
    _OtpChannel.max => 'MAX',
    _OtpChannel.sms => 'SMS',
  };

  IconData get icon => switch (this) {
    _OtpChannel.telegram => Icons.send_rounded,
    _OtpChannel.max => Icons.chat_bubble_rounded,
    _OtpChannel.sms => Icons.sms_rounded,
  };

  Color get color => switch (this) {
    _OtpChannel.telegram => const Color(0xFF26A5E4),
    _OtpChannel.max => const Color(0xFF6B4FBB),
    _OtpChannel.sms => AppColors.primaryBrown,
  };
}

/// Экран подтверждения номера телефона при регистрации — открывается из
/// AuthScreen после нажатия «Зарегистрироваться» (см. auth_screen.dart).
///
/// ВАЖНО — это UI-каркас поверх демо-логики, не рабочая интеграция:
/// приложение НЕ может само стучаться в Telegram Gateway API / MAX с
/// секретным токеном — это должен делать бэкенд (см. пояснение в чате).
/// Здесь код "приходит" мгновенно и правильный код всегда '0000' —
/// это заглушка до появления реального бэкенда, как и остальные mock-
/// экраны приложения (авторизация, заказы и т.д.).
///
/// Порядок каналов — как попросили: сначала Telegram (реально работающий
/// официальный Telegram Gateway API), при неудаче — MAX (пока нет
/// официального самостоятельного OTP-шлюза уровня Telegram Gateway,
/// поэтому в реальной интеграции этот шаг может быть недоступен вплоть
/// до появления такого API — см. пояснение в чате), и SMS как гарантированный
/// финальный канал.
class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String displayName;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.displayName,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  static const _codeLength = 4;
  static const _demoCorrectCode = '0000';
  static const _resendCooldown = Duration(seconds: 45);

  final List<TextEditingController> _digitControllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List.generate(_codeLength, (_) => FocusNode());

  _OtpChannel _channel = _OtpChannel.telegram;
  Timer? _cooldownTimer;
  Duration _remaining = _resendCooldown;
  bool _error = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _remaining = _resendCooldown;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _resend([_OtpChannel? nextChannel]) {
    setState(() {
      if (nextChannel != null) _channel = nextChannel;
      _error = false;
      for (final c in _digitControllers) {
        c.clear();
      }
    });
    _digitFocusNodes.first.requestFocus();
    _startCooldown();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) return;
    if (index < _codeLength - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    } else {
      _digitFocusNodes[index].unfocus();
    }
    final code = _digitControllers.map((c) => c.text).join();
    if (code.length == _codeLength) _verifyCode(code);
  }

  Future<void> _verifyCode(String code) async {
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (code == _demoCorrectCode) {
      context.read<AuthProvider>().markLoggedIn(displayName: widget.displayName);
      Navigator.of(context)
        ..pop()
        ..maybePop();
    } else {
      setState(() {
        _verifying = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining == Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 28),
              Text('Подтвердите номер', style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.rowLabelMuted,
                  children: [
                    const TextSpan(text: 'Мы отправили код на '),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ChannelBadge(channel: _channel),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) => _digitBox(i)),
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text(
                  'Неверный код. Проверьте и попробуйте ещё раз.',
                  style: TextStyle(color: Color(0xFFB5544A), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 28),
              if (!canResend)
                Text(
                  'Отправить код повторно можно через ${_remaining.inSeconds} сек.',
                  style: AppTextStyles.rowLabelMuted,
                )
              else ...[
                _ResendOption(
                  label: 'Отправить код ещё раз в ${_channel.label}',
                  onTap: () => _resend(),
                ),
                if (_channel == _OtpChannel.telegram) ...[
                  const SizedBox(height: 10),
                  _ResendOption(
                    label: 'Не пришло? Отправить через MAX',
                    onTap: () => _resend(_OtpChannel.max),
                  ),
                ],
                const SizedBox(height: 10),
                _ResendOption(
                  label: 'Отправить кодом по SMS',
                  onTap: () => _resend(_OtpChannel.sms),
                ),
              ],
              const Spacer(),
              if (_verifying)
                const Center(child: CircularProgressIndicator(color: AppColors.primaryBrown)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitBox(int index) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _digitFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _error ? const Color(0xFFB5544A) : AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _error ? const Color(0xFFB5544A) : AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryBrown, width: 2),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final _OtpChannel channel;
  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: channel.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(channel.icon, size: 16, color: channel.color),
          const SizedBox(width: 7),
          Text(
            'Код отправлен в ${channel.label}',
            style: TextStyle(color: channel.color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ResendOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ResendOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(color: AppColors.linkAccent, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
