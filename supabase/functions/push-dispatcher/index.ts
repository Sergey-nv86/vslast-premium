import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-secret",
};

async function getFirebaseAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const now = Math.floor(Date.now() / 1000);

  const base64UrlEncode = (value: Uint8Array | string): string => {
    const bytes =
      typeof value === "string" ? encoder.encode(value) : value;

    let binary = "";
    for (const byte of bytes) {
      binary += String.fromCharCode(byte);
    }

    return btoa(binary)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
  };

  const header = base64UrlEncode(
    JSON.stringify({
      alg: "RS256",
      typ: "JWT",
    }),
  );

  const claim = base64UrlEncode(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const pem = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(
    atob(pem),
    (c) => c.charCodeAt(0),
  );

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signingInput = `${header}.${claim}`;

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  const jwt =
    `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const response = await fetch(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body:
        `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`,
    },
  );

  if (!response.ok) {
    throw new Error(
      `Google OAuth error: ${response.status} ${await response.text()}`,
    );
  }

  const data = await response.json();

  if (!data.access_token) {
    throw new Error("Google OAuth response has no access_token");
  }

  return data.access_token;
}

function getNotificationContent(
  eventType: string,
  payload: Record<string, unknown>,
): { title: string; body: string } {
  const orderNumber = payload.order_number
    ? `№${payload.order_number}`
    : "";

  const isPreorder = payload.is_preorder === true;
  const status = String(payload.status ?? "");
  const oldStatus = String(payload.old_status ?? "");

  switch (eventType) {
    case "order_created":
      return isPreorder
        ? {
            title: "Предзаказ оформлен",
            body: orderNumber
              ? `Предзаказ ${orderNumber} принят`
              : "Ваш предзаказ принят",
          }
        : {
            title: "Заказ оформлен",
            body: orderNumber
              ? `Заказ ${orderNumber} принят`
              : "Ваш заказ принят",
          };

    case "new_order_admin":
      return {
        title: "Новый заказ",
        body: orderNumber
          ? `Поступил новый заказ ${orderNumber}`
          : "Поступил новый заказ",
      };

    case "new_preorder_admin":
      return {
        title: "Новый предзаказ",
        body: orderNumber
          ? `Поступил новый предзаказ ${orderNumber}`
          : "Поступил новый предзаказ",
      };

    case "order_status_changed":
      if (status === "confirmed" && oldStatus === "pending_confirmation") {
        return {
          title: "Заказ подтверждён",
          body: orderNumber
            ? `Заказ ${orderNumber} подтверждён`
            : "Ваш заказ подтверждён",
        };
      }

      if (status === "completed" && oldStatus === "confirmed") {
        return {
          title: "Заказ выполнен",
          body: orderNumber
            ? `Заказ ${orderNumber} выполнен`
            : "Ваш заказ выполнен",
        };
      }

      return {
        title: "Статус заказа изменён",
        body: orderNumber
          ? `Статус заказа ${orderNumber} изменён`
          : "Статус вашего заказа изменён",
      };

    case "order_ready":
      return {
        title: "Заказ готов",
        body: orderNumber
          ? `Заказ ${orderNumber} готов к получению`
          : "Ваш заказ готов к получению",
      };

    case "preorder_confirmed":
      return {
        title: "Предзаказ подтверждён",
        body: orderNumber
          ? `Предзаказ ${orderNumber} подтверждён`
          : "Ваш предзаказ подтверждён",
      };

    case "order_cancelled":
      return {
        title: "Заказ отменён",
        body: orderNumber
          ? `Заказ ${orderNumber} отменён`
          : "Ваш заказ отменён",
      };

    default:
      return {
        title: "Всласть",
        body: "Новое уведомление",
      };
  }
}

function isInvalidFcmToken(result: unknown): boolean {
  const text = JSON.stringify(result ?? {}).toUpperCase();

  return (
    text.includes("UNREGISTERED") ||
    text.includes("REGISTRATION_TOKEN_NOT_REGISTERED") ||
    text.includes("INVALID_ARGUMENT")
  );
}

async function sendToToken(
  deviceToken: string,
  title: string,
  body: string,
  type: string,
  orderId: string,
  projectId: string,
  accessToken: string,
) {
  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,

          // DATA-ONLY MESSAGE.
          //
          // Не передаём notification и webpush.fcm_options.link.
          // Иначе Firebase/browser сам обрабатывает click и
          // возвращает уже открытую страницу PWA.
          //
          // Service Worker сам создаст notification и полностью
          // контролирует notificationclick.
          data: {
            type: String(type),
            order_id: String(orderId),
            title: String(title),
            body: String(body),
          },
        },
      }),
    },
  );

  const result = await fcmResponse.json();

  return {
    success: fcmResponse.ok,
    message_id: result.name ?? null,
    error: fcmResponse.ok ? null : result,
    invalid_token: !fcmResponse.ok && isInvalidFcmToken(result),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return Response.json(
        { error: "Supabase secrets are not configured" },
        { status: 500, headers: corsHeaders },
      );
    }

    const suppliedSecret = req.headers.get("x-push-secret");
    const dispatcherSecret = Deno.env.get("PUSH_DISPATCHER_SECRET");

    if (!dispatcherSecret || !suppliedSecret || suppliedSecret !== dispatcherSecret) {
      return Response.json(
        { error: "Unauthorized" },
        { status: 401, headers: corsHeaders },
      );
    }

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    const requestBody = await req.json();

    /*
     * ------------------------------------------------------------
     * MODE 1: Existing direct FCM test / manual send
     * ------------------------------------------------------------
     */
    const {
      token,
      user_id,
      title = "Всласть",
      body = "Тестовый push из Supabase",
      type = "test",
      order_id = "",
    } = requestBody;

    if (token || user_id) {
      let tokens: string[] = [];

      if (token) {
        tokens = [token];
      } else {
        const { data, error } = await supabase
          .from("user_devices")
          .select("id,fcm_token")
          .eq("user_id", user_id)
          .eq("is_active", true);

        if (error) {
          throw new Error(
            `user_devices query failed: ${error.message}`,
          );
        }

        tokens = (data ?? [])
          .map((row) => row.fcm_token)
          .filter(
            (value): value is string =>
              typeof value === "string" && value.length > 0,
          );
      }

      if (tokens.length === 0) {
        return Response.json(
          { error: "No active FCM devices found" },
          { status: 404, headers: corsHeaders },
        );
      }

      const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
      const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
      const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");

      if (!projectId || !clientEmail || !privateKey) {
        return Response.json(
          { error: "Firebase secrets are not configured" },
          { status: 500, headers: corsHeaders },
        );
      }

      const accessToken = await getFirebaseAccessToken(
        clientEmail,
        privateKey,
      );

      const results = [];

      for (const deviceToken of tokens) {
        const result = await sendToToken(
          deviceToken,
          title,
          body,
          String(type),
          String(order_id),
          projectId,
          accessToken,
        );

        results.push(result);
      }

      return Response.json(
        {
          success: results.some((item) => item.success),
          devices_found: tokens.length,
          results,
        },
        { headers: corsHeaders },
      );
    }

    /*
     * ------------------------------------------------------------
     * MODE 2: Process one push_events record
     * ------------------------------------------------------------
     */
    const eventId =
      requestBody.event_id ??
      requestBody.record?.id ??
      requestBody.record?.event_id;

    if (!eventId) {
      return Response.json(
        {
          error:
            "event_id is required for push event processing",
        },
        { status: 400, headers: corsHeaders },
      );
    }

    /*
     * Atomically claim the event.
     * Only pending events can become processing.
     */
    const { data: claimedEvent, error: claimError } = await supabase
      .from("push_events")
      .update({
        status: "processing",
        processing_started_at: new Date().toISOString(),
        attempts: 1,
        error_message: null,
      })
      .eq("id", eventId)
      .eq("status", "pending")
      .select(
        "id,event_type,recipient_user_id,order_id,payload,attempts",
      )
      .maybeSingle();

    if (claimError) {
      throw new Error(
        `push_events claim failed: ${claimError.message}`,
      );
    }

    if (!claimedEvent) {
      return Response.json(
        {
          success: false,
          error:
            "Event is not pending or does not exist",
        },
        { status: 409, headers: corsHeaders },
      );
    }

    const eventPayload =
      claimedEvent.payload &&
      typeof claimedEvent.payload === "object"
        ? claimedEvent.payload as Record<string, unknown>
        : {};

    const content = getNotificationContent(
      claimedEvent.event_type,
      eventPayload,
    );

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
    const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");

    if (!projectId || !clientEmail || !privateKey) {
      await supabase
        .from("push_events")
        .update({
          status: "failed",
          error_message: "Firebase secrets are not configured",
        })
        .eq("id", eventId);

      return Response.json(
        { error: "Firebase secrets are not configured" },
        { status: 500, headers: corsHeaders },
      );
    }

    const accessToken = await getFirebaseAccessToken(
      clientEmail,
      privateKey,
    );

    const { data: devices, error: devicesError } = await supabase
      .from("user_devices")
      .select("id,fcm_token")
      .eq("user_id", claimedEvent.recipient_user_id)
      .eq("is_active", true);

    if (devicesError) {
      await supabase
        .from("push_events")
        .update({
          status: "failed",
          error_message: devicesError.message,
        })
        .eq("id", eventId);

      throw new Error(
        `user_devices query failed: ${devicesError.message}`,
      );
    }

    if (!devices || devices.length === 0) {
      await supabase
        .from("push_events")
        .update({
          status: "failed",
          error_message: "No active FCM devices found",
        })
        .eq("id", eventId);

      return Response.json(
        {
          success: false,
          event_id: eventId,
          devices_found: 0,
        },
        { status: 404, headers: corsHeaders },
      );
    }

    const results = [];

    for (const device of devices) {
      const result = await sendToToken(
        device.fcm_token,
        content.title,
        content.body,
        claimedEvent.event_type,
        claimedEvent.order_id ?? "",
        projectId,
        accessToken,
      );

      results.push({
        device_id: device.id,
        ...result,
      });

      /*
       * FCM token is no longer usable.
       * Deactivate it so future pushes do not repeatedly fail.
       */
      if (result.invalid_token) {
        await supabase
          .from("user_devices")
          .update({
            is_active: false,
            updated_at: new Date().toISOString(),
          })
          .eq("id", device.id);
      }
    }

    const successful = results.filter(
      (item) => item.success,
    ).length;

    if (successful > 0) {
      await supabase
        .from("push_events")
        .update({
          status: "sent",
          sent_at: new Date().toISOString(),
          error_message: null,
        })
        .eq("id", eventId);
    } else {
      const errorText = JSON.stringify(results);

      await supabase
        .from("push_events")
        .update({
          status: "failed",
          error_message: errorText.slice(0, 4000),
        })
        .eq("id", eventId);
    }

    return Response.json(
      {
        success: successful > 0,
        event_id: eventId,
        event_type: claimedEvent.event_type,
        devices_found: devices.length,
        devices_sent: successful,
        results,
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    console.error("push-dispatcher error:", error);

    return Response.json(
      {
        error:
          error instanceof Error
            ? error.message
            : String(error),
      },
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});
