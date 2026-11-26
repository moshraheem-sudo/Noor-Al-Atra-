// Supabase Edge Function: sharia-search
// Searches published Islamic jurisprudence Q&As from Almojib (almojib.com)
// and returns normalized JSON without storing user queries or personal data.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

// Simple per-isolate rate limiter (max 30 requests/minute per client IP)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_MAX = 30;
const RATE_LIMIT_WINDOW_MS = 60_000;

function isRateLimited(clientIp: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(clientIp);
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(clientIp, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }
  if (entry.count >= RATE_LIMIT_MAX) {
    return true;
  }
  entry.count += 1;
  return false;
}

interface ShariaAnswerResult {
  id: number | null;
  title: string;
  question: string;
  answer: string;
  source: string | null;
  category: string | null;
  reference: string | null;
  url: string | null;
  createdAt: string | null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const clientIp = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";
  if (isRateLimited(clientIp)) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "تم تجاوز الحد المسموح من الطلبات، يرجى الانتظار دقيقة ثم المحاولة مجدداً.",
      }),
      {
        status: 429,
        headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }

  try {
    let rawQuery = "";
    let page = 1;
    let marjaId: number | null = null;

    if (req.method === "GET") {
      const url = new URL(req.url);
      rawQuery = url.searchParams.get("query") ?? url.searchParams.get("q") ?? url.searchParams.get("search") ?? "";
      const pageParam = Number(url.searchParams.get("page") ?? "1");
      if (Number.isFinite(pageParam) && pageParam >= 1) page = Math.floor(pageParam);
      const marjaParam = Number(url.searchParams.get("marja_id") ?? url.searchParams.get("marjaId") ?? "");
      if (Number.isFinite(marjaParam) && marjaParam > 0) marjaId = Math.floor(marjaParam);
    } else if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      rawQuery = String(body?.query ?? body?.q ?? body?.search ?? "");
      const pageParam = Number(body?.page ?? 1);
      if (Number.isFinite(pageParam) && pageParam >= 1) page = Math.floor(pageParam);
      const marjaParam = Number(body?.marja_id ?? body?.marjaId ?? "");
      if (Number.isFinite(marjaParam) && marjaParam > 0) marjaId = Math.floor(marjaParam);
    } else {
      return new Response(
        JSON.stringify({ success: false, error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } },
      );
    }

    const query = rawQuery.trim().replace(/\s+/g, " ");
    if (!query || query.length < 2) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "يرجى إدخال كلمة بحث واضحة (حرفين على الأقل).",
          results: [],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } },
      );
    }

    if (query.length > 300) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "نص البحث طويل جداً، يرجى اختصاره إلى أقل من 300 حرف.",
          results: [],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } },
      );
    }

    const encodedQuery = encodeURIComponent(query);
    const marjaQuery = marjaId ? `&marja_id=${marjaId}` : "";
    const targetUrl = `https://api.almojib.com/ar/api/v1.1/faq/search?search=${encodedQuery}&page=${page}${marjaQuery}`;
    const fallbackUrl = `https://almojib.com/ar/search?search=${encodedQuery}${marjaQuery}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12_000);

    let upstreamRes: Response;
    try {
      upstreamRes = await fetch(targetUrl, {
        method: "GET",
        headers: {
          Accept: "application/json, text/plain, */*",
          "User-Agent": "NoorAlAtra-ShariaSearch/1.0",
        },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!upstreamRes.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          query,
          error: `تعذر الوصول إلى مصدر المجيب (رمز ${upstreamRes.status}).`,
          fallbackUrl,
          results: [],
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } },
      );
    }

    const payload = await upstreamRes.json();
    const rawItems = Array.isArray(payload?.outcome?.data) ? payload.outcome.data : [];
    const total = typeof payload?.outcome?.meta?.total === "number" ? payload.outcome.meta.total : rawItems.length;

    const results: ShariaAnswerResult[] = [];
    for (const item of rawItems) {
      const qObj = item?.question ?? {};
      const replyObj = item?.first_reply ?? null;

      const questionText = String(qObj?.question ?? "").trim();
      const titleText = String(qObj?.subject ?? "").trim() || questionText;
      const answerText = String(replyObj?.reply ?? "").trim();

      // Skip entries without an actual published question/answer
      if (!questionText && !titleText) continue;

      const marjasArr = Array.isArray(replyObj?.marjas) ? replyObj.marjas : [];
      const marjaNames = marjasArr
        .map((m: { name?: string }) => String(m?.name ?? "").trim())
        .filter((n: string) => n.length > 0);
      const reference = marjaNames.length > 0 ? marjaNames.join("، ") : null;

      const instituteName = String(replyObj?.institute?.name ?? "").trim() || "موقع المجيب";
      const categoryName = String(qObj?.category?.name ?? "").trim() || null;
      const id = typeof qObj?.id === "number" ? qObj.id : null;
      const shareUrl = String(qObj?.share_link ?? "").trim() || (id ? `https://almojib.com/ar/question/${id}` : null);
      const createdAt = String(replyObj?.created_at ?? qObj?.created_at ?? "").trim() || null;

      results.push({
        id,
        title: titleText,
        question: questionText || titleText,
        answer: answerText || "الإجابة منشورة في المصدر الأصلي.",
        source: instituteName,
        category: categoryName,
        reference,
        url: shareUrl,
        createdAt,
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        query,
        page,
        total,
        results,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
      },
    );
  } catch (err) {
    const isAbort = err instanceof DOMException && err.name === "AbortError";
    return new Response(
      JSON.stringify({
        success: false,
        error: isAbort
          ? "انتهت مهلة الاتصال بموقع المجيب، يرجى المحاولة مرة أخرى."
          : "حدث خطأ غير متوقع أثناء معالجة البحث.",
        results: [],
      }),
      {
        status: isAbort ? 504 : 500,
        headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }
});
