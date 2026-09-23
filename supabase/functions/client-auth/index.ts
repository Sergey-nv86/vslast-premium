import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DUMMY_EMAIL = "invalid-client-id@auth.vslast.internal";
const AUTH_DOMAIN = "auth.vslast.internal";
const CONSENT_VERSION = "1.0";

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizeClientId(value: unknown): string {
  return String(value ?? "").trim().toUpperCase();
}

function validClientId(value: string): boolean {
  return /^C-\d{6}$/.test(value);
}

function validPassword(value: string): boolean {
  return value.length >= 6;
}

function getSecretKey(): string {
  const key =
    Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    "";

  if (!key) {
    throw new Error("Supabase secret key is not configured");
  }

  return key;
}

function createAdminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) throw new Error("SUPABASE_URL is not configured");

  return createClient(url, getSecretKey(), {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

async function signInByClientId(
  supabase: ReturnType<typeof createAdminClient>,
  clientId: string,
  password: string,
) {
  const { data: account } = await supabase
    .from("client_accounts")
    .select("legacy_user_id, status")
    .eq("client_id", clientId)
    .maybeSingle();

  let email = DUMMY_EMAIL;

  if (account?.status === "active" && account.legacy_user_id) {
    const { data: authUser } = await supabase.auth.admin.getUserById(
      account.legacy_user_id,
    );

    if (authUser.user?.email) {
      email = authUser.user.email;
    }
  }

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error || !data.session || !data.user) {
    return null;
  }

  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in,
    expires_at: data.session.expires_at,
    user: data.user,
  };
}

async function notifyAdminsOfClientEvent(
  supabase: ReturnType<typeof createAdminClient>,
  eventType: "client_registered_admin" | "client_login_admin",
  clientId: string,
  clientUserId: string,
) {
  try {
    const { data: admins, error } = await supabase
      .from("profiles")
      .select("id")
      .eq("is_active", true)
      .in("role", ["owner", "admin", "manager", "seller"]);

    if (error) {
      console.error("[client-auth] admin notification lookup failed", error);
      return;
    }

    for (const admin of admins ?? []) {
      const adminId = String(admin.id ?? "").trim();
      if (!adminId || adminId === clientUserId) continue;

      const dedupKey = eventType === "client_registered_admin"
        ? "client_registered_admin:" + clientId
        : null;

      const { error: pushError } = await supabase.rpc("enqueue_push_event", {
        p_event_type: eventType,
        p_recipient_user_id: adminId,
        p_recipient_client_id: null,
        p_order_id: null,
        p_payload: {
          type: eventType,
          client_id: clientId,
          client_user_id: clientUserId,
        },
        p_dedup_key: dedupKey,
      });

      if (pushError) {
        console.error(
          "[client-auth] admin notification enqueue failed",
          pushError,
        );
      }
    }

    console.log(
      "[client-auth] admin client event queued: " + eventType + " " + clientId,
    );
  } catch (error) {
    console.error("[client-auth] admin client notification error", error);
  }
}

async function registerClient(
  supabase: ReturnType<typeof createAdminClient>,
  password: string,
  consentPersonalData: boolean,
  acceptTerms: boolean,
  consentMarketing: boolean,
  req: Request,
) {
  if (!consentPersonalData || !acceptTerms) {
    throw new Error("Необходимо подтвердить обязательные документы регистрации.");
  }
  const { data: nextId, error: nextIdError } = await supabase.rpc(
    "next_client_id",
  );

  if (nextIdError || !nextId) {
    throw new Error("Не удалось получить новый идентификатор клиента.");
  }

  const clientId = normalizeClientId(nextId);
  if (!validClientId(clientId)) {
    throw new Error("Сервис вернул некорректный идентификатор клиента.");
  }

  const syntheticEmail = `${clientId.toLowerCase()}@${AUTH_DOMAIN}`;

  const { data: created, error: createError } =
    await supabase.auth.admin.createUser({
      email: syntheticEmail,
      password,
      email_confirm: true,
      user_metadata: {
        auth_mode: "client_id",
        client_id: clientId,
      },
    });

  if (createError || !created.user) {
    throw new Error(
      createError?.message ?? "Не удалось создать пользователя.",
    );
  }

  const { error: accountError } = await supabase
    .from("client_accounts")
    .insert({
      client_id: clientId,
      legacy_user_id: created.user.id,
      status: "active",
    });

  if (accountError) {
    await supabase.auth.admin.deleteUser(created.user.id);
    throw new Error("Не удалось сохранить идентификатор клиента.");
  }

  const session = await signInByClientId(supabase, clientId, password);

  if (!session) {
    await supabase.auth.admin.deleteUser(created.user.id);
    throw new Error("Не удалось создать авторизованную сессию.");
  }

  const forwardedFor = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  const ipAddress =
    req.headers.get("cf-connecting-ip")?.trim() ||
    forwardedFor ||
    null;
  const userAgent = req.headers.get("user-agent");

  const consentRows = [
    {
      user_id: created.user.id,
      consent_type: "personal_data_processing",
      document_version: CONSENT_VERSION,
      ip_address: ipAddress,
      user_agent: userAgent,
      source: "registration",
    },
    {
      user_id: created.user.id,
      consent_type: "terms_acceptance",
      document_version: CONSENT_VERSION,
      ip_address: ipAddress,
      user_agent: userAgent,
      source: "registration",
    },
    ...(consentMarketing
      ? [{
          user_id: created.user.id,
          consent_type: "marketing",
          document_version: CONSENT_VERSION,
          ip_address: ipAddress,
          user_agent: userAgent,
          source: "registration",
        }]
      : []),
  ];

  const { error: consentError } = await supabase
    .from("consents")
    .insert(consentRows);

  if (consentError) {
    await supabase
      .from("client_accounts")
      .delete()
      .eq("legacy_user_id", created.user.id);
    await supabase.auth.admin.deleteUser(created.user.id);
    throw new Error("Не удалось зафиксировать согласия пользователя.");
  }

  await notifyAdminsOfClientEvent(
    supabase,
    "client_registered_admin",
    clientId,
    created.user.id,
  );

  return {
    ...session,
    client_id: clientId,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const action = String(body?.action ?? "").trim().toLowerCase();
    const password = String(body?.password ?? "");

    if (!validPassword(password)) {
      return json({ error: "Пароль должен содержать минимум 6 символов." }, 400);
    }

    const supabase = createAdminClient();

    if (action === "login") {
      const clientId = normalizeClientId(body?.client_id);

      if (!validClientId(clientId)) {
        return json({ error: "Введите корректный ID клиента." }, 400);
      }

      const session = await signInByClientId(supabase, clientId, password);

      if (!session) {
        return json({ error: "Неверный ID клиента или пароль." }, 401);
      }

      await notifyAdminsOfClientEvent(
        supabase,
        "client_login_admin",
        clientId,
        session.user.id,
      );

      return json({
        client_id: clientId,
        ...session,
      });
    }

    if (action === "register") {
      const session = await registerClient(
        supabase,
        password,
        Boolean(body?.consent_personal_data),
        Boolean(body?.accept_terms),
        Boolean(body?.consent_marketing),
        req,
      );

      return json(session, 201);
    }

    return json({ error: "Unknown action" }, 400);
  } catch (error) {
    console.error("[client-auth]", error);

    return json(
      {
        error: error instanceof Error
          ? error.message
          : "Не удалось выполнить операцию.",
      },
      500,
    );
  }
});
