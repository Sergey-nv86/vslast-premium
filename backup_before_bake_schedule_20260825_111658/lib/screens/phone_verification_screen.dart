import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/telegram_otp_service.dart';
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

  String get description => switch (this) {
    _OtpChannel.telegram =>
      'Рекомендуем — реальное подтверждение через Telegram',
    _OtpChannel.max => 'Будет подключено после появления реального OTP-шлюза',
    _OtpChannel.sms => 'Резервный канал — подключим SMS-провайдера',
  };
}

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String displayName;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.displayName,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  static const _codeLength = 6;

  final TelegramOtpService _telegramOtp = TelegramOtpService();

  final List<TextEditingController> _digitControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _digitFocusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  _OtpChannel? _channel;
  String? _requestId;
  Timer? _cooldownTimer;
  Duration _remaining = Duration.zero;

  bool _error = false;
  bool _sending = false;
  bool _verifying = false;
  String? _errorText;

  @override
  void dispose() {
    _cooldownTimer?.cancel();

    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }

    _telegramOtp.dispose();
    super.dispose();
  }

  Future<void> _selectChannel(_OtpChannel channel) async {
    if (_sending) return;

    if (channel != _OtpChannel.telegram) {
      _showUnavailableChannel(channel);
      return;
    }

    setState(() {
      _channel = channel;
      _error = false;
      _errorText = null;
      _sending = true;

      for (final c in _digitControllers) {
        c.clear();
      }
    });

    try {
      final result = await _telegramOtp.start(phoneNumber: widget.phoneNumber);

      if (!mounted) return;

      setState(() {
        _requestId = result.requestId;
        _sending = false;
        _remaining = Duration(seconds: result.resendAfterSeconds);
      });

      _startCooldown();
      _digitFocusNodes.first.requestFocus();
    } on TelegramOtpException catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error = true;
        _errorText = e.message;
        _remaining = Duration(seconds: e.retryAfterSeconds ?? 0);
      });

      if (_remaining > Duration.zero) {
        _startCooldown();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error = true;
        _errorText = 'Не удалось отправить код. Попробуйте ещё раз.';
      });
    }
  }

  void _showUnavailableChannel(_OtpChannel channel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          channel == _OtpChannel.max
              ? 'MAX пока не подключён как OTP-канал.'
              : 'SMS пока не подключён. Сейчас доступен Telegram.',
        ),
      ),
    );
  }

  void _changeChannel() {
    _cooldownTimer?.cancel();

    setState(() {
      _channel = null;
      _requestId = null;
      _remaining = Duration.zero;
      _error = false;
      _errorText = null;
      _sending = false;
      _verifying = false;

      for (final c in _digitControllers) {
        c.clear();
      }
    });
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();

    if (_remaining <= Duration.zero) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  Future<void> _resend() async {
    if (_channel != _OtpChannel.telegram ||
        _remaining != Duration.zero ||
        _sending) {
      return;
    }

    await _selectChannel(_OtpChannel.telegram);
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) return;

    if (index < _codeLength - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    } else {
      _digitFocusNodes[index].unfocus();
    }

    final code = _digitControllers.map((c) => c.text).join();

    if (code.length == _codeLength) {
      _verifyCode(code);
    }
  }

  Future<void> _verifyCode(String code) async {
    final requestId = _requestId;

    if (requestId == null || _verifying) return;

    setState(() {
      _verifying = true;
      _error = false;
      _errorText = null;
    });

    try {
      await _telegramOtp.verify(requestId: requestId, code: code);

      if (!mounted) return;

      context.read<AuthProvider>().markLoggedIn(
        displayName: widget.displayName,
      );

      Navigator.of(context)
        ..pop()
        ..maybePop();
    } on TelegramOtpException catch (e) {
      if (!mounted) return;

      setState(() {
        _verifying = false;
        _error = true;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _verifying = false;
        _error = true;
        _errorText = 'Не удалось проверить код. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CloseButton(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 28),
              Expanded(
                child: _channel == null
                    ? _buildChannelSelection()
                    : _buildCodeVerification(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelSelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Как получить код?', style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.rowLabelMuted,
              children: [
                const TextSpan(text: 'Подтверждение номера '),
                TextSpan(
                  text: widget.phoneNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ChannelOption(
            channel: _OtpChannel.telegram,
            recommended: true,
            onTap: () => _selectChannel(_OtpChannel.telegram),
          ),
          const SizedBox(height: 12),
          _ChannelOption(
            channel: _OtpChannel.max,
            recommended: true,
            onTap: () => _selectChannel(_OtpChannel.max),
          ),
          const SizedBox(height: 12),
          _ChannelOption(
            channel: _OtpChannel.sms,
            recommended: false,
            onTap: () => _selectChannel(_OtpChannel.sms),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.primaryBrown,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Приоритетная регистрация — через Telegram или MAX. '
                    'Сейчас реальное подтверждение доступно через Telegram.',
                    style: AppTextStyles.rowLabelMuted.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeVerification() {
    final canResend = _remaining == Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Подтвердите номер', style: AppTextStyles.screenTitle),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: AppTextStyles.rowLabelMuted,
            children: [
              const TextSpan(text: 'Мы отправили код на '),
              TextSpan(
                text: widget.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChannelBadge(channel: _channel!),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _changeChannel,
          behavior: HitTestBehavior.opaque,
          child: const Text(
            'Изменить способ получения кода',
            style: TextStyle(
              color: AppColors.linkAccent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_codeLength, (i) => _digitBox(i)),
        ),
        if (_error && _errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: const TextStyle(
              color: Color(0xFFB5544A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 28),
        if (!canResend)
          Text(
            'Повторная отправка через ${_remaining.inSeconds} сек.',
            style: AppTextStyles.rowLabelMuted,
          )
        else
          GestureDetector(
            onTap: _resend,
            child: const Text(
              'Отправить код ещё раз в Telegram',
              style: TextStyle(
                color: AppColors.linkAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        const Spacer(),
        if (_sending)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBrown),
          ),
        if (_verifying)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBrown),
          ),
      ],
    );
  }

  Widget _digitBox(int index) {
    return SizedBox(
      width: 50,
      height: 64,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _digitFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: !_sending && !_verifying,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _error ? const Color(0xFFB5544A) : AppColors.divider,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _error ? const Color(0xFFB5544A) : AppColors.divider,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryBrown,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.close, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ChannelOption extends StatelessWidget {
  final _OtpChannel channel;
  final bool recommended;
  final VoidCallback onTap;

  const _ChannelOption({
    required this.channel,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: recommended
                ? channel.color.withValues(alpha: .28)
                : AppColors.divider,
            width: recommended ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: channel.color.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(channel.icon, color: channel.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        channel.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: channel.color.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Рекомендуем',
                            style: TextStyle(
                              color: channel.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(channel.description, style: AppTextStyles.rowLabelMuted),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
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
            style: TextStyle(
              color: channel.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
