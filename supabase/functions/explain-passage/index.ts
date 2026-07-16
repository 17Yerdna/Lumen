import { createClient } from "npm:@supabase/supabase-js@2.95.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const instructions = `Eres el asistente de estudio de Lumen Biblia.
Responde en español claro, pastoral y prudente. Separa la respuesta con estos
títulos: CONTEXTO, PERSPECTIVA ADVENTISTA, OTRAS INTERPRETACIONES, APLICACIÓN
y FUENTES. Distingue los hechos del texto de las interpretaciones. Para la
perspectiva adventista usa solo fuentes encontradas en los dominios permitidos.
Si no encuentras una fuente pertinente, dilo; no inventes citas. De Ellen G.
White usa como máximo una cita de 20 palabras y enlaza la fuente. En FUENTES
incluye las referencias bíblicas y las URL completas realmente utilizadas.
No presentes la respuesta como consejo médico, legal ni como autoridad pastoral.`;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return jsonError("Método no permitido.", 405);

  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  const url = Deno.env.get("SUPABASE_URL");
  const secret = Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  if (!url || !secret || !openAiKey) {
    return jsonError("El asistente aún no está configurado.", 503);
  }

  const admin = createClient(url, secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await admin.auth.getUser(token);
  if (authError || !user) return jsonError("Sesión no válida.", 401);

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return jsonError("Solicitud no válida.", 400);
  }
  const reference = typeof body.reference === "string"
    ? body.reference.trim()
    : "";
  const text = typeof body.text === "string" ? body.text.trim() : "";
  const question = typeof body.question === "string" && body.question.trim()
    ? body.question.trim()
    : "Explica este pasaje en su contexto.";
  if (
    !reference || reference.length > 100 || !text || text.length > 12000 ||
    question.length > 1000
  ) return jsonError("El pasaje o la pregunta no son válidos.", 400);

  const dailyLimit = positiveEnv("ASSISTANT_DAILY_LIMIT", 10);
  const monthlyLimit = positiveEnv("ASSISTANT_MONTHLY_LIMIT", 1000);
  const { data: quota, error: quotaError } = await admin.rpc(
    "consume_assistant_quota",
    {
      p_user_id: user.id,
      p_daily_limit: dailyLimit,
      p_monthly_limit: monthlyLimit,
    },
  );
  if (quotaError) return jsonError("No se pudo comprobar la cuota.", 503);
  const allowance = quota?.[0];
  if (!allowance?.allowed) {
    return jsonError("Alcanzaste el límite diario del asistente.", 429);
  }

  const upstream = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${openAiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_MODEL") ?? "gpt-5.6-luna",
      instructions,
      input: `Pasaje: ${reference}\n\nTexto:\n${text}\n\nPregunta: ${question}`,
      reasoning: { effort: "low" },
      max_output_tokens: 1800,
      stream: true,
      store: false,
      safety_identifier: user.id,
      prompt_cache_key: "lumen-bible-explainer-v1",
      tools: [{
        type: "web_search",
        search_context_size: "low",
        filters: {
          allowed_domains: [
            "adventist.org",
            "adventistbiblicalresearch.org",
            "egwwritings.org",
            "whiteestate.org",
          ],
        },
      }],
    }),
  });
  if (!upstream.ok || !upstream.body) {
    console.error("OpenAI request failed", upstream.status);
    return jsonError("El servicio de explicación no respondió.", 502);
  }

  return new Response(upstream.body, {
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache",
      "x-daily-remaining": `${allowance.daily_remaining}`,
    },
  });
});

function jsonError(error: string, status: number) {
  return Response.json({ error }, { status, headers: corsHeaders });
}

function positiveEnv(name: string, fallback: number) {
  const value = Number.parseInt(Deno.env.get(name) ?? "", 10);
  return Number.isInteger(value) && value > 0 ? value : fallback;
}
