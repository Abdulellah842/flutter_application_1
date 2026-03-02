# إعداد الحسابات والنشر العام

## 1) إعداد Firebase

1. أنشئ مشروع Firebase جديد.
2. فعّل:
- `Authentication`:
  - Email/Password
  - Phone
- `Cloud Firestore`
- `Hosting`

3. أضف تطبيق Web داخل Firebase وخذ القيم التالية:
- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `authDomain`
- `storageBucket` (اختياري)

## 2) تشغيل Flutter مع إعدادات Firebase

شغّل التطبيق بهذه المتغيرات:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=LLM_API_URL=http://localhost:8080/assistant/chat \
  --dart-define=LLM_MODEL=gpt-4o-mini
```

## 3) نشر الموقع كرابط عام

1. ثبّت Firebase CLI:

```bash
npm i -g firebase-tools
```

2. سجل دخول:

```bash
firebase login
```

3. اربط المشروع:
- انسخ `.firebaserc.example` إلى `.firebaserc`
- عدّل `project-id`

4. ابنِ نسخة الويب:

```bash
flutter build web \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=LLM_API_URL=https://your-backend-domain/assistant/chat \
  --dart-define=LLM_MODEL=gpt-4o-mini
```

5. انشر:

```bash
firebase deploy --only hosting,firestore:rules
```

بعدها يصير عندك رابط:
- `https://your-project-id.web.app`
- `https://your-project-id.firebaseapp.com`
