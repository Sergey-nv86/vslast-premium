import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...headers, "Content-Type": "application/json" } });

const normalize = (s: string) => s.trim().toLocaleLowerCase("ru-RU").replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ").trim();
const baseUnit = (u: string) => {
  const v = u.toLowerCase().trim();
  if (["мл", "л", "ml", "l"].includes(v)) return "ml";
  if (["шт", "pcs", "pc"].includes(v)) return "pcs";
  return "g";
};
const toBase = (q: number, u: string, b: string): number | null => {
  const v = u.toLowerCase().replace(/\./g, "").trim();
  if (b === "g") {
    if (["г", "гр", "g", "грамм", "грамма", "граммов"].includes(v)) return q;
    if (["кг", "kg", "килограмм", "килограмма"].includes(v)) return q * 1000;
  }
  if (b === "ml") {
    if (["мл", "ml"].includes(v)) return q;
    if (["л", "l", "литр", "литра", "литров"].includes(v)) return q * 1000;
  }
  if (b === "pcs" && ["шт", "pcs", "pc"].includes(v)) return q;
  return null;
};

const schema = {
  type: "object", additionalProperties: false,
  required: ["product_name", "technology", "yield_quantity", "yield_unit", "items", "notes"],
  properties: {
    product_name: { type: "string" }, technology: { type: "string" },
    yield_quantity: { type: ["number", "null"] }, yield_unit: { type: ["string", "null"] },
    notes: { type: "array", items: { type: "string" } },
    items: { type: "array", items: {
      type: "object", additionalProperties: false,
      required: ["ingredient_name", "ingredient_id", "quantity", "unit", "notes"],
      properties: {
        ingredient_name: { type: "string" }, ingredient_id: { type: ["string", "null"] }, quantity: { type: "number" },
        unit: { type: "string" }, notes: { type: "string" }
      }
    }}
  }
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);
  try {
    const auth = req.headers.get("Authorization") || "";
    if (!auth.startsWith("Bearer ")) return reply({ error: "Требуется вход в приложение" }, 401);
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!url || !serviceKey || !openaiKey) return reply({ error: "Сервер не настроен: проверьте секреты Supabase" }, 500);

    const db = createClient(url, serviceKey, { auth: { persistSession: false } });
    const token = auth.slice(7);
    const { data: authData, error: authError } = await db.auth.getUser(token);
    if (authError || !authData.user) return reply({ error: "Сессия истекла. Войдите повторно." }, 401);

    const { data: profile, error: profileError } = await db.from("profiles").select("role").eq("id", authData.user.id).maybeSingle();
    if (profileError || !profile || !["owner", "admin", "manager", "baker", "pastry_chef"].includes(String(profile.role))) {
      return reply({ error: "Нет доступа к технологическим картам" }, 403);
    }

    const body = await req.json();
    const photos = Array.isArray(body.images) ? body.images : [];
    if (!photos.length || photos.length > 8) return reply({ error: "Добавьте от 1 до 8 фотографий" }, 400);
    const bytes = photos.reduce((n: number, p: any) => n + (typeof p.data === "string" ? p.data.length : 0), 0);
    if (bytes > 22_000_000) return reply({ error: "Фотографии слишком большие. Уменьшите их размер." }, 413);

    const { data: catalog, error: catalogError } = await db.from("ingredients")
      .select("id,name,normalized_name,base_unit,calories_per_100,protein_per_100,fat_per_100,carbs_per_100,needs_review,ingredient_prices(purchase_quantity,purchase_unit,purchase_price,price_per_base_unit)")
      .order("name");
    if (catalogError) throw catalogError;
    const ingredients = catalog ?? [];

    const content: any[] = [{
      type: "input_text",
      text: "Ты — технолог пекарни-кондитерской. Считай только то, что видно на фото. Перепиши название, технологию, выход и ингредиенты с точными количествами и единицами. Не выдумывай пропущенные данные. Если текст неразборчив или единица сомнительна, укажи это в notes. Сопоставь ингредиент с точным id из справочника, если он подходит. Иначе ingredient_id = null. Справочник ингредиентов для сопоставления: " + JSON.stringify(ingredients.map((x: any) => ({ id: x.id, name: x.name, base_unit: x.base_unit })))
    }];
    for (const photo of photos) {
      if (typeof photo.data !== "string" || photo.data.length < 100) return reply({ error: "Некорректная фотография" }, 400);
      const mime = ["image/jpeg", "image/png", "image/webp"].includes(photo.mime_type) ? photo.mime_type : "image/jpeg";
      content.push({ type: "input_image", image_url: "data:" + mime + ";base64," + photo.data, detail: "high" });
    }

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { Authorization: "Bearer " + openaiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") || "gpt-4.1-mini",
        input: [{ role: "user", content }],
        text: { format: { type: "json_schema", name: "recipe_tech_card", strict: true, schema } }
      })
    });
    if (!response.ok) {
      console.error("OpenAI error", response.status, await response.text());
      return reply({ error: "Не удалось распознать рецепт. Проверьте качество фотографий и повторите." }, 502);
    }
    const ai = await response.json();
    const text = ai.output_text || ai.output?.flatMap((x: any) => x.content || []).find((x: any) => x.type === "output_text")?.text;
    if (!text) throw new Error("OpenAI returned empty output");
    const parsed = JSON.parse(text);

    const calculated = [];
    for (const row of parsed.items || []) {
      const name = String(row.ingredient_name || "").trim();
      const normalized = normalize(name);
      const quantity = Number(row.quantity);
      if (!name || !normalized || !Number.isFinite(quantity) || quantity < 0) continue;
      let ingredient = ingredients.find((x: any) => row.ingredient_id && x.id === row.ingredient_id) || ingredients.find((x: any) => x.normalized_name === normalized);
      if (!ingredient) {
        const unit = baseUnit(String(row.unit || ""));
        const { data, error } = await db.from("ingredients").upsert({
          name, normalized_name: normalized, base_unit: unit, needs_review: true
        }, { onConflict: "normalized_name" }).select("id,name,normalized_name,base_unit,calories_per_100,protein_per_100,fat_per_100,carbs_per_100,needs_review").single();
        if (error) throw error;
        ingredient = { ...data, ingredient_prices: [] };
        ingredients.push(ingredient);
      }
      const price = Array.isArray(ingredient.ingredient_prices) ? ingredient.ingredient_prices[0] : null;
      const qtyBase = toBase(quantity, String(row.unit || ""), ingredient.base_unit);
      const perUnit = price?.price_per_base_unit == null ? null : Number(price.price_per_base_unit);
      const lineCost = qtyBase != null && perUnit != null ? Math.round(qtyBase * perUnit * 100) / 100 : null;
      calculated.push({
        ingredient_id: ingredient.id, ingredient_name: ingredient.name,
        quantity, unit: row.unit, base_unit: ingredient.base_unit,
        base_quantity: qtyBase, line_cost: lineCost,
        price_missing: lineCost == null, needs_review: ingredient.needs_review === true, notes: row.notes || "",
        nutrition: {
          calories: ingredient.calories_per_100 == null ? null : Number(ingredient.calories_per_100),
          protein: ingredient.protein_per_100 == null ? null : Number(ingredient.protein_per_100),
          fat: ingredient.fat_per_100 == null ? null : Number(ingredient.fat_per_100),
          carbs: ingredient.carbs_per_100 == null ? null : Number(ingredient.carbs_per_100)
        }
      });
    }
    const missing = calculated.filter(x => x.price_missing).map(x => ({ id: x.ingredient_id, name: x.ingredient_name, unit: x.base_unit }));
    const total = missing.length ? null : Math.round(calculated.reduce((s, x) => s + (x.line_cost || 0), 0) * 100) / 100;

    let nutrition = null;
    const nutritionComplete = calculated.length > 0 && calculated.every(x =>
      x.base_unit === "g" && x.base_quantity !== null && Object.values(x.nutrition).every(v => v !== null));
    const yieldQty = Number(parsed.yield_quantity);
    const yieldUnit = String(parsed.yield_unit || "").toLowerCase();
    const yieldGrams = yieldUnit === "kg" ? yieldQty * 1000 : yieldUnit === "g" ? yieldQty : null;
    if (nutritionComplete && yieldGrams && yieldGrams > 0) {
      const totals = { calories: 0, protein: 0, fat: 0, carbs: 0 };
      for (const x of calculated) {
        totals.calories += x.base_quantity / 100 * x.nutrition.calories;
        totals.protein += x.base_quantity / 100 * x.nutrition.protein;
        totals.fat += x.base_quantity / 100 * x.nutrition.fat;
        totals.carbs += x.base_quantity / 100 * x.nutrition.carbs;
      }
      nutrition = Object.fromEntries(Object.entries(totals).map(([k, v]) => [k, Math.round(v / yieldGrams * 10000) / 100]));
    }
    return reply({
      analysis: parsed, items: calculated, total_cost: total, missing_prices: missing,
      nutrition_per_100: nutrition, nutrition_status: nutrition ? (calculated.some(x => x.needs_review) ? "estimated" : "calculated") : "incomplete",
      calculation_status: missing.length ? "needs_prices" : "ready"
    });
  } catch (error) {
    console.error("recipe-tech-card failure", error);
    return reply({ error: error instanceof Error ? error.message : "Внутренняя ошибка" }, 500);
  }
});
