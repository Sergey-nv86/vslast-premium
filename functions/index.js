'use strict';

const crypto = require('crypto');

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

initializeApp();

const db = getFirestore();
const telegramGatewayToken = defineSecret('TELEGRAM_GATEWAY_TOKEN');

const REGION = 'europe-west1';
const TELEGRAM_API = 'https://gatewayapi.telegram.org';
const OTP_TTL_SECONDS = 300;
const RESEND_COOLDOWN_SECONDS = 45;
const MAX_VERIFY_ATTEMPTS = 5;


// TEMPORARY FCM TEST FUNCTION.
// Remove after successful end-to-end push verification.
exports.testFcmPush = onRequest(
  {
    region: REGION,
  },
  async (req, res) => {
    try {
      const token = String(req.body?.token || req.query?.token || '').trim();

      if (!token) {
        return json(res, 400, {
          ok: false,
          error: 'FCM_TOKEN_REQUIRED',
        });
      }

      const message = {
        token,
        notification: {
          title: 'Всласть',
          body: 'Тестовое push-уведомление работает 🎉',
        },
        data: {
          type: 'test',
          source: 'testFcmPush',
        },
        webpush: {
          notification: {
            title: 'Всласть',
            body: 'Тестовое push-уведомление работает 🎉',
          },
        },
      };

      const messageId = await getMessaging().send(message);

      console.log('TEST FCM PUSH SENT', {
        messageId,
      });

      return json(res, 200, {
        ok: true,
        messageId,
      });
    } catch (error) {
      console.error('TEST FCM PUSH ERROR', error);

      return json(res, 500, {
        ok: false,
        error: String(error?.message || error),
        code: error?.code || null,
      });
    }
  },
);

function json(res, status, body) {
  res.status(status).set('Content-Type', 'application/json').send(body);
}

function normalizePhone(value) {
  const raw = String(value || '').trim();
  const digits = raw.replace(/\D/g, '');

  // Russian phone numbers are accepted from the current registration UI.
  // Convert 8XXXXXXXXXX -> +7XXXXXXXXXX.
  if (digits.length === 11 && digits.startsWith('8')) {
    return `+7${digits.slice(1)}`;
  }

  if (digits.length === 11 && digits.startsWith('7')) {
    return `+${digits}`;
  }

  if (raw.startsWith('+') && digits.length >= 10 && digits.length <= 15) {
    return `+${digits}`;
  }

  throw new Error('PHONE_NUMBER_INVALID');
}

function phoneHash(phone) {
  return crypto.createHash('sha256').update(phone).digest('hex');
}

function requirePost(req, res) {
  if (req.method !== 'POST') {
    json(res, 405, { ok: false, error: 'METHOD_NOT_ALLOWED' });
    return false;
  }
  return true;
}

async function telegramRequest(method, body) {
  const response = await fetch(`${TELEGRAM_API}/${method}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${telegramGatewayToken.value()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new Error(`TELEGRAM_HTTP_${response.status}`);
  }

  if (!response.ok || payload.ok !== true) {
    const error = payload && payload.error
      ? String(payload.error)
      : `TELEGRAM_HTTP_${response.status}`;
    throw new Error(error);
  }

  return payload.result;
}

exports.telegramOtpStart = onRequest(
  {
    region: REGION,
    cors: [
      'https://vslast-premium.web.app',
      'https://vslast-premium.firebaseapp.com',
      /^http:\/\/localhost(:\d+)?$/,
      /^http:\/\/127\.0\.0\.1(:\d+)?$/,
    ],
    secrets: [telegramGatewayToken],
    timeoutSeconds: 30,
    maxInstances: 10,
  },
  async (req, res) => {
    if (!requirePost(req, res)) return;

    try {
      const phone = normalizePhone(req.body?.phoneNumber);

      const rateRef = db.collection('otpRateLimits').doc(phoneHash(phone));
      const rateSnap = await rateRef.get();
      const rate = rateSnap.exists ? rateSnap.data() : null;

      if (rate?.lastSentAt?.toMillis) {
        const elapsed = Math.floor(
          (Date.now() - rate.lastSentAt.toMillis()) / 1000,
        );

        if (elapsed < RESEND_COOLDOWN_SECONDS) {
          json(res, 429, {
            ok: false,
            error: 'OTP_COOLDOWN',
            retryAfterSeconds: RESEND_COOLDOWN_SECONDS - elapsed,
          });
          return;
        }
      }

      // Проверяем, может ли Telegram доставить OTP на этот номер.
      //
      // ВАЖНО: успешный checkSendAbility резервирует стоимость одного
      // сообщения. Полученный request_id передаём в
      // sendVerificationMessage, чтобы второй раз не тарифицировать
      // эту отправку.
      const abilityResult = await telegramRequest('checkSendAbility', {
        phone_number: phone,
      });

      const abilityRequestId = String(abilityResult.request_id || '');

      if (!abilityRequestId) {
        throw new Error('TELEGRAM_CHECK_ABILITY_FAILED');
      }

      const result = await telegramRequest('sendVerificationMessage', {
        phone_number: phone,
        request_id: abilityRequestId,
        code_length: 6,
        ttl: OTP_TTL_SECONDS,
        payload: 'vslast-registration',
      });

      const requestId = String(result.request_id || abilityRequestId);

      await db.collection('otpSessions').doc(requestId).set({
        phone,
        channel: 'telegram',
        status: 'sent',
        attempts: 0,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(
          Date.now() + OTP_TTL_SECONDS * 1000,
        ),
      });

      await rateRef.set({
        phone,
        lastSentAt: FieldValue.serverTimestamp(),
        activeRequestId: requestId,
      }, { merge: true });

      json(res, 200, {
        ok: true,
        channel: 'telegram',
        requestId,
        expiresInSeconds: OTP_TTL_SECONDS,
        resendAfterSeconds: RESEND_COOLDOWN_SECONDS,
        requestCost: result.request_cost ?? abilityResult.request_cost ?? null,
        remainingBalance:
          result.remaining_balance ?? abilityResult.remaining_balance ?? null,
      });
    } catch (error) {
      console.error('telegramOtpStart:', error);

      const message = String(error.message || error);

      if (message.includes('PHONE_NUMBER_INVALID')) {
        json(res, 400, { ok: false, error: 'PHONE_NUMBER_INVALID' });
        return;
      }

      if (
        message.includes('ACCESS_TOKEN_INVALID') ||
        message.includes('UNAUTHORIZED')
      ) {
        json(res, 500, { ok: false, error: 'TELEGRAM_CONFIGURATION_ERROR' });
        return;
      }

      // Telegram не может доставить Gateway-сообщение на этот номер.
      // Это нормальный сценарий: Flutter сможет предложить MAX или SMS.
      const telegramUnavailableErrors = [
        'USER_NOT_FOUND',
        'PHONE_NUMBER_INVALID',
        'PHONE_NUMBER_NOT_REGISTERED',
        'USER_NOT_REACHABLE',
        'RECIPIENT_NOT_FOUND',
        'RECIPIENT_NOT_AVAILABLE',
        'TELEGRAM_CHECK_ABILITY_FAILED',
      ];

      if (telegramUnavailableErrors.some((code) => message.includes(code))) {
        json(res, 422, {
          ok: false,
          error: 'TELEGRAM_UNAVAILABLE',
          channel: 'telegram',
        });
        return;
      }

      json(res, 502, {
        ok: false,
        error: 'TELEGRAM_SEND_FAILED',
      });
    }
  },
);

exports.telegramOtpVerify = onRequest(
  {
    region: REGION,
    cors: [
      'https://vslast-premium.web.app',
      'https://vslast-premium.firebaseapp.com',
      /^http:\/\/localhost(:\d+)?$/,
      /^http:\/\/127\.0\.0\.1(:\d+)?$/,
    ],
    secrets: [telegramGatewayToken],
    timeoutSeconds: 30,
    maxInstances: 10,
  },
  async (req, res) => {
    if (!requirePost(req, res)) return;

    try {
      const requestId = String(req.body?.requestId || '').trim();
      const code = String(req.body?.code || '').trim();

      if (!requestId || !/^\d{4,8}$/.test(code)) {
        json(res, 400, { ok: false, error: 'INVALID_CODE_REQUEST' });
        return;
      }

      const sessionRef = db.collection('otpSessions').doc(requestId);
      const sessionSnap = await sessionRef.get();

      if (!sessionSnap.exists) {
        json(res, 404, { ok: false, error: 'OTP_SESSION_NOT_FOUND' });
        return;
      }

      const session = sessionSnap.data();

      if (session.status === 'verified') {
        json(res, 409, { ok: false, error: 'OTP_ALREADY_VERIFIED' });
        return;
      }

      if (
        session.expiresAt?.toMillis &&
        session.expiresAt.toMillis() < Date.now()
      ) {
        await sessionRef.update({ status: 'expired' });
        json(res, 410, { ok: false, error: 'OTP_EXPIRED' });
        return;
      }

      const attempts = Number(session.attempts || 0);

      if (attempts >= MAX_VERIFY_ATTEMPTS) {
        await sessionRef.update({ status: 'blocked' });
        json(res, 429, {
          ok: false,
          error: 'OTP_MAX_ATTEMPTS',
        });
        return;
      }

      const result = await telegramRequest('checkVerificationStatus', {
        request_id: requestId,
        code,
      });

      const verificationStatus =
        result?.verification_status?.status || 'unknown';

      await sessionRef.update({
        attempts: FieldValue.increment(1),
        lastVerificationAt: FieldValue.serverTimestamp(),
      });

      if (verificationStatus !== 'code_valid') {
        if (verificationStatus === 'expired') {
          await sessionRef.update({ status: 'expired' });
          json(res, 410, { ok: false, error: 'OTP_EXPIRED' });
          return;
        }

        if (verificationStatus === 'code_max_attempts_exceeded') {
          await sessionRef.update({ status: 'blocked' });
          json(res, 429, { ok: false, error: 'OTP_MAX_ATTEMPTS' });
          return;
        }

        json(res, 401, {
          ok: false,
          error: 'OTP_INVALID',
          attemptsRemaining: Math.max(
            0,
            MAX_VERIFY_ATTEMPTS - attempts - 1,
          ),
        });
        return;
      }

      await sessionRef.update({
        status: 'verified',
        verifiedAt: FieldValue.serverTimestamp(),
      });

      json(res, 200, {
        ok: true,
        verified: true,
        channel: 'telegram',
        phoneNumber: session.phone,
      });
    } catch (error) {
      console.error('telegramOtpVerify:', error);

      const message = String(error.message || error);

      if (message.includes('ACCESS_TOKEN_INVALID')) {
        json(res, 500, {
          ok: false,
          error: 'TELEGRAM_CONFIGURATION_ERROR',
        });
        return;
      }

      json(res, 502, {
        ok: false,
        error: 'TELEGRAM_VERIFY_FAILED',
      });
    }
  },
);
