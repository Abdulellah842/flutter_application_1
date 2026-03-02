import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

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
    `You are the in-app Personal Assistant for Focus Guardian.\n` +
    `Reply in Arabic unless the user asks otherwise.\n` +
    `Always answer the user's latest prompt directly in the first 1-2 lines.\n` +
    `Do not ignore the user's request. Do not answer randomly.\n` +
    `Use user context to provide concrete and actionable guidance.\n` +
    `You are connected to: tasks, habits, kids monitoring, progress, sleep, phone usage, study plans.\n` +
    `Avoid generic advice; personalize response using the provided context.\n` +
    `If the user asks for a plan, provide short structured steps.\n` +
    `If user is overloaded, reduce tasks and prioritize essentials.\n` +
    `If kids context indicates device should stay locked, mention study-first flow.\n` +
    `Locale: ${locale}`;

  const trimmedHistory = Array.isArray(history) ? history.slice(-10) : [];
  const input = [
    {
      role: 'system',
      content: [{ type: 'text', text: systemPrompt }],
    },
    {
      role: 'system',
      content: [
        {
          type: 'text',
          text: `USER_CONTEXT_JSON:\n${JSON.stringify(context, null, 2)}`,
        },
      ],
    },
    ...trimmedHistory.map((m) => ({
      role: m?.role === 'assistant' ? 'assistant' : 'user',
      content: [{ type: 'text', text: typeof m?.content === 'string' ? m.content : '' }],
    })),
    {
      role: 'user',
      content: [{ type: 'text', text: prompt }],
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

  return 'تم استلام طلبك، لكن لم أتمكن من توليد رد مناسب الآن. حاول مرة ثانية.';
}

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(port, () => {
  console.log(`Assistant backend listening on http://localhost:${port}`);
});
