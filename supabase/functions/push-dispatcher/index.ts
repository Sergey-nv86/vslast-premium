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
    const bytes = typeof value === "string" ? encoder.encode(value) : value;
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };

  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64UrlEncode(JSON.stringify({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const pem = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signingInput = `${header}.${claim}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`,
  });

  if (!response.ok) {
    throw new Error(`Google OAuth error: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  if (!data.access_token) throw new Error("Google OAuth response has no access_token");
  return data.access_token;
}

function getNotificationContent(
  eventType: string,
  payload: Record<string, unknown>,
): { title: string; body: string } {
  const orderNumber = payload.order_number ? `№${payload.order_number}` : "";
  const isPreorder = payload.is_preorder === true;
  const status = String(payload.status ?? "");
  const oldStatus = String(payload.old_status ?? "");
  const clientId = String(payload.client_id ?? "");
  const productName = String(payload.product_name ?? "Товар");
  const assortmentDate = String(payload.assortment_date ?? "");

  switch (eventType) {
    case "client_registered_admin":
      return {
        title: "Новый клиент",
        body: `Клиент ${clientId} зарегистрировался и вошёл в приложение`,
      };

    case "client_login_admin":
      return {
        title: "Вход клиента",
        body: `Клиент ${clientId} вошёл в приложение`,
      };

    case "chat_message":
      return {
        title: "Новое сообщение в чате «Всласть»",
        body: String(payload.message_preview ?? "У вас новое сообщение в чате."),
      };

    case "chat_message_admin":
      return {
        title: "Новое сообщение в чате «Всласть»",
        body: String(payload.message_preview ?? "Клиент отправил новое сообщение."),
      };

    case "order_created":
      return isPreorder
        ? {
            title: "Предзаказ оформлен",
            body: orderNumber ? `Предзаказ ${orderNumber} принят` : "Ваш предзаказ принят",
          }
        : {
            title: "Заказ оформлен",
            body: orderNumber ? `Заказ ${orderNumber} принят` : "Ваш заказ принят",
          };

    case "new_order_admin":
      return {
        title: "Новый заказ",
        body: orderNumber ? `Поступил новый заказ ${orderNumber}` : "Поступил новый заказ",
      };

    case "new_preorder_admin":
      return {
        title: "Новый предзаказ",
        body: orderNumber ? `Поступил новый предзаказ ${orderNumber}` : "Поступил новый предзаказ",
      };

    case "order_confirmed":
      return {
        title: "Заказ подтверждён",
        body: orderNumber ? `Заказ ${orderNumber} подтверждён` : "Ваш заказ подтверждён",
      };

    case "order_completed":
      return {
        title: "Заказ выполнен",
        body: orderNumber ? `Заказ ${orderNumber} выполнен` : "Ваш заказ выполнен",
      };

    case "order_changed":
      return {
        title: "Заказ изменён",
        body: orderNumber ? `Изменён заказ ${orderNumber}` : "Данные заказа изменены",
      };

    case "order_status_changed":
      if (status === "confirmed" && oldStatus === "pending_confirmation") {
        return {
          title: "Заказ подтверждён",
          body: orderNumber ? `Заказ ${orderNumber} подтверждён` : "Ваш заказ подтверждён",
        };
      }
      if (status === "completed") {
        return {
          title: "Заказ выполнен",
          body: orderNumber ? `Заказ ${orderNumber} выполнен` : "Ваш заказ выполнен",
        };
      }
      if (status === "cancelled" || status === "canceled") {
        return {
          title: "Заказ отменён",
          body: orderNumber ? `Заказ ${orderNumber} отменён` : "Ваш заказ отменён",
        };
      }
      return {
        title: "Статус заказа изменён",
        body: orderNumber ? `Статус заказа ${orderNumber} изменён` : "Статус вашего заказа изменён",
      };

    case "order_ready":
      return {
        title: "Заказ готов",
        body: orderNumber ? `Заказ ${orderNumber} готов к получению` : "Ваш заказ готов к получению",
      };

    case "preorder_confirmed":
      return {
        title: "Предзаказ подтверждён",
        body: orderNumber ? `Предзаказ ${orderNumber} подтверждён` : "Ваш предзаказ подтверждён",
      };

    case "order_cancelled":
      return {
        title: "Заказ отменён",
        body: orderNumber ? `Заказ ${orderNumber} отменён` : "Ваш заказ отменён",
      };

    case "pickup_reminder":
      return {
        title: "Напоминание о получении",
        body: orderNumber ? `Заказ ${orderNumber} можно будет забрать примерно через час` : "До получения заказа около часа",
      };

    case "favorite_product_back_in_stock":
      return {
        title: "Товар снова в наличии",
        body: productName,
      };

    case "new_product_published":
      return {
        title: "Новый товар",
        body: `${productName} появился в каталоге`,
      };

    case "fresh_bakery_published":
      return {
        title: "Свежая выпечка",
        body: String(payload.message ?? "В каталоге появилась свежая выпечка"),
      };

    case "promotion_published":
      return {
        title: "Новая акция",
        body: String(payload.promotion_title ?? "Появилась новая акция"),
      };

    case "daily_assortment_published":
      return {
        title: "Витрина обновлена",
        body: assortmentDate ? `Витрина на ${assortmentDate} опубликована` : "Сегодняшняя витрина опубликована",
      };

    case "admin_assortment_reminder":
      return {
        title: "Не опубликована витрина",
        body: assortmentDate ? `Опубликуйте витрину на ${assortmentDate}` : "Опубликуйте сегодняшнюю витрину",
      };

    case "admin_assortment_overdue":
      return {
        title: "Витрина просрочена",
        body: assortmentDate ? `Витрина на ${assortmentDate} ещё не опубликована` : "Сегодняшняя витрина ещё не опубликована",
      };

    case "cart_abandoned":
      return {
        title: "Корзина ждёт вас",
        body: "Вы оставили товары в корзине — возможно, пора вернуться.",
      };

    case "crm_inactive":
      return {
        title: "Мы скучаем",
        body: "Давно не виделись в «Всласть». Загляните посмотреть свежую выпечку.",
      };

    case "crm_bonus_granted":
      return {
        title: "Вам начислены бонусы",
        body: `${Number(payload.bonus_amount ?? 0).toLocaleString("ru-RU")} бонусов уже на вашем счёте.`,
      };

    case "crm_bonus_redeemed":
      return {
        title: "Бонусы списаны",
        body: `${Number(payload.bonus_amount ?? 0).toLocaleString("ru-RU")} бонусов списано с вашего счёта.`,
      };

    case "crm_bonus_expiring":
      return {
        title: "Бонусы скоро сгорят",
        body: `${Number(payload.bonus_amount ?? 0).toLocaleString("ru-RU")} бонусов скоро сгорит.`,
      };

    default:
      return { title: "Всласть", body: "Новое уведомление" };
  }
}

function buildNavigationData(
  type: string,
  orderId: string,
  threadId: string,
  payload: Record<string, unknown> = {},
): Record<string, string> {
  const data: Record<string, string> = {
    type: String(type),
    order_id: String(orderId || payload.order_id || ""),
    thread_id: String(threadId || payload.thread_id || ""),
    product_id: String(payload.product_id ?? ""),
    message_id: String(payload.message_id ?? ""),
    client_id: String(payload.client_id ?? ""),
    client_user_id: String(payload.client_user_id ?? ""),
    promotion_id: String(payload.promotion_id ?? ""),
    assortment_date: String(payload.assortment_date ?? ""),
    cart_id: String(payload.cart_id ?? ""),
    title: String(payload.title ?? ""),
    body: String(payload.body ?? ""),
  };

  return data;
}

function isInvalidFcmToken(result: unknown): boolean {
  const text = JSON.stringify(result ?? {}).toUpperCase();
  return text.includes("UNREGISTERED") ||
    text.includes("REGISTRATION_TOKEN_NOT_REGISTERED") ||
    text.includes("INVALID_ARGUMENT");
}

async function sendToToken(
  deviceToken: string,
  title: string,
  body: string,
  type: string,
  orderId: string,
  threadId: string,
  projectId: string,
  accessToken: string,
  navigationPayload: Record<string, unknown> = {},
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
          notification: {
            title: String(title),
            body: String(body),
          },
          data: buildNavigationData(
            type,
            orderId,
            threadId,
            {
              ...navigationPayload,
              title,
              body,
            },
          ),
          android: {
            priority: "high",
            notification: {
              channel_id: "vslast_messages",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
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
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return Response.json({ error: "Supabase secrets are not configured" }, { status: 500, headers: corsHeaders });
    }

    const suppliedSecret = req.headers.get("x-push-secret");
    const dispatcherSecret = Deno.env.get("PUSH_DISPATCHER_SECRET");
    if (!dispatcherSecret || !suppliedSecret || suppliedSecret !== dispatcherSecret) {
      return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const requestBody = await req.json();

    const {
      token,
      client_id,
      user_id,
      title = "Всласть",
      body = "Тестовый push из Supabase",
      type = "test",
      order_id = "",
    } = requestBody;

    if (token || client_id || user_id) {
      let tokens: string[] = [];
      let devices: Array<{ id: string; fcm_token: string }> = [];

      if (token) {
        tokens = [token];
      } else {
        if (client_id) {
          const { data, error } = await supabase
            .from("user_devices")
            .select("id,fcm_token")
            .eq("client_id", client_id)
            .eq("is_active", true);
          if (error) throw new Error(`user_devices client_id query failed: ${error.message}`);
          devices = (data ?? []) as Array<{ id: string; fcm_token: string }>;
        }
        if (devices.length === 0 && user_id) {
          const { data, error } = await supabase
            .from("user_devices")
            .select("id,fcm_token")
            .eq("user_id", user_id)
            .eq("is_active", true);
          if (error) throw new Error(`user_devices user_id query failed: ${error.message}`);
          devices = (data ?? []) as Array<{ id: string; fcm_token: string }>;
        }
        tokens = devices
          .map((row) => row.fcm_token)
          .filter((value): value is string => typeof value === "string" && value.length > 0);
      }

      if (tokens.length === 0) {
        return Response.json({ error: "No active FCM devices found" }, { status: 404, headers: corsHeaders });
      }

      const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
      const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
      const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
      if (!projectId || !clientEmail || !privateKey) {
        return Response.json({ error: "Firebase secrets are not configured" }, { status: 500, headers: corsHeaders });
      }

      const accessToken = await getFirebaseAccessToken(clientEmail, privateKey);
      const results = [];
      for (const deviceToken of tokens) {
        results.push(await sendToToken(
          deviceToken,
          title,
          body,
          String(type),
          String(order_id),
          String(requestBody.thread_id ?? ""),
          projectId,
          accessToken,
          requestBody,
        ));
      }

      return Response.json(
        { success: results.some((item) => item.success), devices_found: tokens.length, results },
        { headers: corsHeaders },
      );
    }

    const eventId = requestBody.event_id ?? requestBody.record?.id ?? requestBody.record?.event_id;
    if (!eventId) {
      return Response.json({ error: "event_id is required for push event processing" }, { status: 400, headers: corsHeaders });
    }

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
      .select("id,event_type,recipient_user_id,recipient_client_id,order_id,payload,attempts")
      .maybeSingle();

    if (claimError) throw new Error(`push_events claim failed: ${claimError.message}`);
    if (!claimedEvent) {
      return Response.json({ success: false, error: "Event is not pending or does not exist" }, { status: 409, headers: corsHeaders });
    }

    const eventPayload = claimedEvent.payload && typeof claimedEvent.payload === "object"
      ? claimedEvent.payload as Record<string, unknown>
      : {};

    const content = getNotificationContent(claimedEvent.event_type, eventPayload);
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
    const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");

    if (!projectId || !clientEmail || !privateKey) {
      await supabase.from("push_events").update({ status: "failed", error_message: "Firebase secrets are not configured" }).eq("id", eventId);
      return Response.json({ error: "Firebase secrets are not configured" }, { status: 500, headers: corsHeaders });
    }

    const accessToken = await getFirebaseAccessToken(clientEmail, privateKey);
    let devices: Array<{ id: string; fcm_token: string }> = [];
    let deviceLookup = "client_id";

    if (claimedEvent.recipient_client_id) {
      const { data, error } = await supabase
        .from("user_devices")
        .select("id,fcm_token")
        .eq("client_id", claimedEvent.recipient_client_id)
        .eq("is_active", true);
      if (error) {
        await supabase.from("push_events").update({ status: "failed", error_message: error.message }).eq("id", eventId);
        throw new Error(`user_devices client_id query failed: ${error.message}`);
      }
      devices = (data ?? []) as Array<{ id: string; fcm_token: string }>;
    }

    if (devices.length === 0 && claimedEvent.recipient_user_id) {
      deviceLookup = "user_id_fallback";
      const { data, error } = await supabase
        .from("user_devices")
        .select("id,fcm_token")
        .eq("user_id", claimedEvent.recipient_user_id)
        .eq("is_active", true);
      if (error) {
        await supabase.from("push_events").update({ status: "failed", error_message: error.message }).eq("id", eventId);
        throw new Error(`user_devices user_id query failed: ${error.message}`);
      }
      devices = (data ?? []) as Array<{ id: string; fcm_token: string }>;
    }

    if (!devices || devices.length === 0) {
      await supabase.from("push_events").update({ status: "failed", error_message: "No active FCM devices found" }).eq("id", eventId);
      return Response.json(
        { success: false, event_id: eventId, devices_found: 0, device_lookup: deviceLookup },
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
        String(eventPayload.thread_id ?? ""),
        projectId,
        accessToken,
        eventPayload,
      );
      results.push({ device_id: device.id, ...result });
      if (result.invalid_token) {
        await supabase.from("user_devices").update({ is_active: false, updated_at: new Date().toISOString() }).eq("id", device.id);
      }
    }

    const successful = results.filter((item) => item.success).length;
    if (successful > 0) {
      await supabase.from("push_events").update({ status: "sent", sent_at: new Date().toISOString(), error_message: null }).eq("id", eventId);
    } else {
      await supabase.from("push_events").update({ status: "failed", error_message: JSON.stringify(results).slice(0, 4000) }).eq("id", eventId);
    }

    return Response.json(
      {
        success: successful > 0,
        event_id: eventId,
        event_type: claimedEvent.event_type,
        devices_found: devices.length,
        devices_sent: successful,
        device_lookup: deviceLookup,
        results,
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    console.error("push-dispatcher error:", error);
    return Response.json(
      { error: error instanceof Error ? error.message : String(error) },
      { status: 500, headers: corsHeaders },
    );
  }
});