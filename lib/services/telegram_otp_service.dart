import 'dart:convert';

import 'package:http/http.dart' as http;

class TelegramOtpException implements Exception {
  final String code;
  final int? retryAfterSeconds;

  const TelegramOtpException(this.code, {this.retryAfterSeconds});

  String get message {
    switch (code) {
      case 'PHONE_NUMBER_INVALID':
        return 'Проверьте номер телефона.';
      case 'OTP_COOLDOWN':
        return 'Повторно отправить код можно через '
            '${retryAfterSeconds ?? 45} сек.';
      case 'OTP_EXPIRED':
        return 'Срок действия кода истёк. Запросите новый код.';
      case 'OTP_MAX_ATTEMPTS':
        return 'Превышено число попыток. Запросите новый код.';
      case 'OTP_INVALID':
        return 'Неверный код. Проверьте код и попробуйте ещё раз.';
      case 'TELEGRAM_CONFIGURATION_ERROR':
        return 'Сервис подтверждения временно недоступен.';
      case 'TELEGRAM_SEND_FAILED':
        return 'Не удалось отправить код в Telegram.';
      case 'TELEGRAM_UNAVAILABLE':
        return 'Telegram недоступен для этого номера. Выберите другой способ получения кода.';
      case 'TELEGRAM_VERIFY_FAILED':
        return 'Не удалось проверить код. Попробуйте ещё раз.';
      default:
        return 'Не удалось подтвердить номер. Попробуйте ещё раз.';
    }
  }

  @override
  String toString() => 'TelegramOtpException($code)';
}

class TelegramOtpStartResult {
  final String requestId;
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final double? requestCost;
  final double? remainingBalance;

  const TelegramOtpStartResult({
    required this.requestId,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    this.requestCost,
    this.remainingBalance,
  });
}

class TelegramOtpService {
  TelegramOtpService({String? baseUrl, http.Client? client})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'OTP_API_BASE_URL',
            defaultValue:
                'https://europe-west1-vslast-premium.cloudfunctions.net',
          ),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<TelegramOtpStartResult> start({required String phoneNumber}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/telegramOtpStart'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );

    final data = _decode(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw TelegramOtpException(
        (data['error']?.toString() ?? 'TELEGRAM_SEND_FAILED'),
        retryAfterSeconds: _asInt(data['retryAfterSeconds']),
      );
    }

    return TelegramOtpStartResult(
      requestId: data['requestId']?.toString() ?? '',
      expiresInSeconds: _asInt(data['expiresInSeconds']) ?? 300,
      resendAfterSeconds: _asInt(data['resendAfterSeconds']) ?? 45,
      requestCost: _asDouble(data['requestCost']),
      remainingBalance: _asDouble(data['remainingBalance']),
    );
  }

  Future<void> verify({required String requestId, required String code}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/telegramOtpVerify'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'requestId': requestId, 'code': code}),
    );

    final data = _decode(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw TelegramOtpException(
        (data['error']?.toString() ?? 'TELEGRAM_VERIFY_FAILED'),
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  void dispose() => _client.close();
}
