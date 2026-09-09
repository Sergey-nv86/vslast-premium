import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DUMMY_EMAIL = "invalid-client-id@auth.vslast.internal";
const AUTH_DOMAIN = "auth.vslast.internal";

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

async function registerClient(
  supabase: ReturnType<typeof createAdminClient>,
  password: string,
) {
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

      return json({
        client_id: clientId,
        ...session,
      });
    }

    if (action === "register") {
      const session = await registerClient(supabase, password);

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
