import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

const port = Number(process.env.PORT || 8080);
const openaiKey = process.env.OPENAI_API_KEY || '';
const defaultModel = process.env.OPENAI_MODEL || 'gpt-4o-mini';

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    service: 'focus-guardian-assistant-backend',
    model: defaultModel,
    hasKey: openaiKey.trim().length > 0,
    now: new Date().toISOString(),
  });
});

app.post('/assistant/chat', async (req, res) => {
  const { model, prompt, context = {}, history = [], locale = 'ar-SA' } = req.body || {};

  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'prompt is required' });
  }

  if (!openaiKey.trim()) {
    return res.status(500).json({
      error: 'OPENAI_API_KEY is missing in backend environment',
    });
  }

  const selectedModel =
    typeof model === 'string' && model.trim().length > 0 ? model.trim() : defaultModel;

  try {
    const reply = await askOpenAI({
      apiKey: openaiKey,
      model: selectedModel,
      prompt,
      context,
      history,
      locale,
    });

    return res.json({
      reply,
      model: selectedModel,
      source: 'openai',
    });
  } catch (error) {
    console.error('[assistant/chat] error:', error);
    return res.status(500).json({
      error: 'Failed to generate assistant reply',
      details: String(error?.message || error),
    });
  }
});

async function askOpenAI({ apiKey, model, prompt, context, history, locale }) {
  const systemPrompt =
    `You are Focus Guardian's Personal Assistant inside the app.\n` +
    `Primary language: Arabic. Switch language only if user clearly requests.\n` +
    `Core behavior rules:\n` +
    `1) Answer the latest user message directly in the first sentence.\n` +
    `2) Never produce random, unrelated, or generic filler text.\n` +
    `3) Personalize using USER_CONTEXT_JSON when relevant.\n` +
    `3.1) Time/date awareness must come from USER_CONTEXT_JSON (current_local_iso/current_date_local/current_time_local/current_weekday_local_ar/current_timezone_offset), not server clock.\n` +
    `4) Keep replies concise and useful. Prefer 3-6 bullet steps when user asks for plan/action.\n` +
    `5) If user message is greeting/small talk (e.g. hi, hello, good morning), respond briefly and ask one useful follow-up.\n` +
    `5.1) If user message is a closing/thanks phrase (e.g. thanks, thank you, appreciate it), reply briefly and end gracefully without asking a follow-up question.\n` +
    `6) If required data is missing, ask one short clarifying question instead of guessing.\n` +
    `7) If user asks about performance/report, return clear metrics and one next action.\n` +
    `8) If user is overloaded, reduce workload and prioritize essentials.\n` +
    `9) If kids context implies study lock, mention study-first flow before device unlock.\n` +
    `Available app domains: tasks, habits, kids monitoring, progress, sleep, phone usage, study plans, finance.\n` +
    `Locale: ${locale}`;

  const trimmedHistory = Array.isArray(history) ? history.slice(-10) : [];
  const input = [
    {
      role: 'system',
      content: [{ type: 'input_text', text: systemPrompt }],
    },
    {
      role: 'system',
      content: [
        {
          type: 'input_text',
          text: `USER_CONTEXT_JSON:\n${JSON.stringify(context, null, 2)}`,
        },
      ],
    },
    ...trimmedHistory.map((m) => {
      const isAssistant = m?.role === 'assistant';
      return {
        role: isAssistant ? 'assistant' : 'user',
        content: [
          {
            type: isAssistant ? 'output_text' : 'input_text',
            text: typeof m?.content === 'string' ? m.content : '',
          },
        ],
      };
    }),
    {
      role: 'user',
      content: [{ type: 'input_text', text: prompt }],
    },
  ];

  const payload = {
    model,
    input,
    temperature: 0.2,
    max_output_tokens: 450,
  };

  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OpenAI HTTP ${response.status}: ${body}`);
  }

  const data = await response.json();

  if (typeof data?.output_text === 'string' && data.output_text.trim()) {
    return data.output_text.trim();
  }

  const blocks = data?.output;
  if (Array.isArray(blocks)) {
    for (const block of blocks) {
      const content = block?.content;
      if (!Array.isArray(content)) continue;
      for (const part of content) {
        const text = part?.text;
        if (typeof text === 'string' && text.trim()) {
          return text.trim();
        }
      }
    }
  }
  return 'ط·آ·ط¢آ§ط·آ·ط¢آ³ط·آ·ط¹آ¾ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¹آ¾ ط·آ·ط¢آ·ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ¨ط·آ¸ط¦â€™ط·آ·ط¥â€™ ط·آ¸أ¢â‚¬â€چط·آ¸ط¦â€™ط·آ¸أ¢â‚¬آ  ط·آ·ط¢آ­ط·آ·ط¢آµط·آ¸أ¢â‚¬â€چط·آ·ط¹آ¾ ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ´ط·آ¸ط¦â€™ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ© ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ¤ط·آ¸أ¢â‚¬ع‘ط·آ·ط¹آ¾ط·آ·ط¢آ© ط·آ¸ط¸آ¾ط·آ¸ط¸آ¹ ط·آ·ط¹آ¾ط·آ¸ط«â€ ط·آ¸أ¢â‚¬â€چط·آ¸ط¸آ¹ط·آ·ط¢آ¯ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ±ط·آ·ط¢آ¯. ط·آ·ط¢آ£ط·آ·ط¢آ¹ط·آ·ط¢آ¯ ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ­ط·آ·ط¢آ§ط·آ¸ط«â€ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ© ط·آ·ط¢آ¨ط·آ·ط¢آ¹ط·آ·ط¢آ¯ ط·آ¸أ¢â‚¬â€چط·آ·ط¢آ­ط·آ·ط¢آ¸ط·آ·ط¢آ§ط·آ·ط¹آ¾.';
}

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(port, () => {
  console.log(`Assistant backend listening on http://localhost:${port}`);
});



