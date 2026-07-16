import { createClient } from "npm:@supabase/supabase-js@2.95.0";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "Método no permitido." }, { status: 405 });
  }
  const url = Deno.env.get("SUPABASE_URL");
  const secret = Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const token = (request.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (!url || !secret || !token) {
    return Response.json({ error: "Servicio no configurado." }, { status: 503 });
  }

  const admin = createClient(url, secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await admin.auth.getUser(token);
  if (authError || !user) {
    return Response.json({ error: "Sesión no válida." }, { status: 401 });
  }
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) {
    console.error("Account deletion failed", error.message);
    return Response.json({ error: "No se pudo eliminar la cuenta." }, {
      status: 500,
    });
  }
  return Response.json({ deleted: true });
});
