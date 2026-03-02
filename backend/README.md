# Assistant Backend

Backend endpoint for the Flutter Personal Assistant screen.

## Endpoints

- `GET /health`
- `POST /assistant/chat`

### POST Body

```json
{
  "model": "gpt-4o-mini",
  "prompt": "يا مساعد رتّب يومي",
  "context": { "commitment_percent": 72 },
  "history": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ],
  "locale": "ar-SA"
}
```

### POST Response

```json
{
  "reply": "النص النهائي للمستخدم...",
  "model": "gpt-4o-mini",
  "source": "openai"
}
```

## Setup

1. Install Node.js 18+.
2. Copy `.env.example` to `.env`.
3. Set your key in `.env`:
   - `OPENAI_API_KEY=...`
4. Install deps:

```bash
npm install
```

5. Run:

```bash
npm start
```

Server runs on `http://localhost:8080` by default.

## Connect Flutter App

Run Flutter with:

```bash
flutter run \
  --dart-define=LLM_API_URL=http://10.0.2.2:8080/assistant/chat \
  --dart-define=LLM_API_TOKEN= \
  --dart-define=LLM_MODEL=gpt-4o-mini
```

Notes:
- For Android emulator use `10.0.2.2`.
- For iOS simulator use `http://localhost:8080/...`.
- On real phone, replace with your PC LAN IP.
