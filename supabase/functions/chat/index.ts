// =====================================================================
// SOKR chat bot (Supabase Edge Function)
// el app bey3t el ras2el hena, w el function di betkalem Gemini
// el GEMINI_API_KEY secret 3la el server bas (msh gowa el app)
// =====================================================================
import { createClient } from "npm:@supabase/supabase-js@2";

// lw el model el awel 3aleh da8t, bngarrab el tany
const MODELS = ["gemini-flash-latest", "gemini-flash-lite-latest"];

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// el t3limat elly bt7aded shakhseyet el bot w 7edoodo
const SYSTEM_PROMPT = `You are "SOKR Assistant", the friendly health assistant inside the SOKR (سكر) app, a diabetes and healthy-living app.
- Answer questions about diabetes, blood sugar, healthy food, exercise, sleep and general wellbeing.
- Reply in the same language the user writes in (Arabic, Egyptian Arabic, Franco-Arabic or English). Keep answers short and clear.
- You can use the user's latest health readings given below to personalize advice.
- NEVER give medicine doses, never tell the user to start, stop or change a medicine, and never give a final diagnosis.
- For medicines, explain general information only and tell the user to ask their doctor or pharmacist.
- If the user mentions emergency signs (very low or very high sugar with symptoms, chest pain, fainting, sudden vision loss), tell them to seek emergency care immediately.
- End medical advice by reminding them to consult their doctor when relevant.`;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json({ error: "GEMINI_API_KEY is not set" }, 500);

    // messages = [{ role: "user" | "model", text: "..." }]
    const { messages } = await req.json();
    if (!Array.isArray(messages) || messages.length === 0) {
      return json({ error: "No messages" }, 400);
    }

    // hena bngeb a5er qeyas se7y lel user (b el token bta3o, fa el RLS sh8ala)
    let healthContext = "No health readings recorded yet.";
    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: authHeader } } },
      );
      const { data } = await supabase
        .from("health_metrics")
        .select("heart_rate, blood_pressure, blood_sugar, weight, height, steps, sleep_hours, recorded_at")
        .order("recorded_at", { ascending: false })
        .limit(1);
      if (data && data.length > 0) {
        healthContext = `User's latest readings: ${JSON.stringify(data[0])}`;
      }
    }

    // bnb3t a5er 12 ras2el bas 3shan el request myb2ash kbeer
    const contents = messages.slice(-12).map((m: { role: string; text: string }) => ({
      role: m.role === "model" ? "model" : "user",
      parts: [{ text: String(m.text).slice(0, 2000) }],
    }));

    const body = JSON.stringify({
      systemInstruction: { parts: [{ text: `${SYSTEM_PROMPT}\n\n${healthContext}` }] },
      contents,
      generationConfig: { temperature: 0.6, maxOutputTokens: 800 },
    });

    // bngarrab kol model le7d ma wa7ed yerod
    let lastError = "";
    for (const model of MODELS) {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        { method: "POST", headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey }, body },
      );
      const result = await res.json();
      if (res.ok) {
        const reply = (result.candidates?.[0]?.content?.parts ?? [])
          .map((p: { text?: string }) => p.text ?? "")
          .join("")
          .trim();
        return json({ reply: reply || "Sorry, I could not answer that. Please try again." });
      }
      lastError = result.error?.message ?? `HTTP ${res.status}`;
    }
    return json({ error: `AI is busy right now. ${lastError}` }, 503);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
