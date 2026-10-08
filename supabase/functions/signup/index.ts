// =====================================================================
// SOKR signup (Supabase Edge Function)
// bey3ml el account 3la el server w y-confirm el email 3la tool
// 3shan mnstanash email confirmation (Supabase el free byb3t 2 emails bas f el sa3a)
// el service role key mawgood 3la el server bas, msh gowa el app
// el trigger f el database bey3ml el profile (dayman patient)
// =====================================================================
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const { email, password, full_name, phone } = await req.json();

    // validation basit
    const cleanEmail = String(email ?? "").trim().toLowerCase();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(cleanEmail)) return json({ error: "Enter a valid email" }, 400);
    if (String(password ?? "").length < 6) return json({ error: "Password must be at least 6 characters" }, 400);
    if (String(full_name ?? "").trim().length < 3) return json({ error: "Enter your full name" }, 400);

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // hena bn3ml el user confirmed (mafish email byetb3t)
    // MOHEM: mnb3tsh "role" hena, fa kol account gedid byb2a patient
    const { error } = await admin.auth.admin.createUser({
      email: cleanEmail,
      password: String(password),
      email_confirm: true,
      user_metadata: {
        full_name: String(full_name).trim(),
        phone: phone ? String(phone).trim() : null,
      },
    });

    if (error) {
      const taken = /already|registered|exists/i.test(error.message);
      return json({ error: taken ? "This email is already registered. Please login." : error.message }, 400);
    }
    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
