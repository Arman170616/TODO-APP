# TODO-APP

A full-stack Todo application with **Django REST API** backend, **Google OAuth** authentication, and two frontends: **Flutter** (mobile) and **Next.js** (web).

## Architecture

```
┌──────────────────────┐                    ┌─────────────┐
│   Flutter (mobile)    │── Google Sign-In ──>│             │
│   + Google Sign-In    │── JWT Bearer ─────>│   Django    │
└──────────────────────┘                    │   REST API  │
                                            │  + JWT Auth │
┌──────────────────────┐                    │  (SQLite)   │
│   Next.js (web)       │── Google OAuth ───>│             │
│   + Google OAuth      │── JWT Bearer ─────>│             │
└──────────────────────┘                    └─────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Django 5 + Django REST Framework |
| Authentication | Google OAuth 2.0 + JWT (SimpleJWT) |
| Database | SQLite |
| Mobile Frontend | Flutter (Dart) + google_sign_in |
| Web Frontend | Next.js 16 + React 19 + Tailwind CSS |
| Communication | REST API (JSON) with JWT Bearer tokens |

## Features

- Google Sign-In authentication (web and mobile)
- User-scoped todos (each user sees only their own)
- Add, complete, and delete todos
- Filter by All / Active / Completed
- Progress bar showing completion status
- Pull-to-refresh (Flutter)
- Real-time sync across web and mobile (same account)
- Gradient UI with card-style design on both platforms

## Project Structure

```
TODO-APP/
├── backend/                   # Django REST API
│   ├── backend/               # Project settings & URLs
│   ├── todos/                 # Todo app
│   │   ├── models.py          # Todo model (with user FK)
│   │   ├── views.py           # API views + Google auth endpoint
│   │   ├── serializers.py     # DRF serializers
│   │   └── urls.py            # API routes
│   └── db.sqlite3             # SQLite database
├── todo_app/                  # Flutter mobile app
│   ├── lib/main.dart          # App source (login + todo screens)
│   └── pubspec.yaml           # Dependencies
└── nextjs-frontend/           # Next.js web app
    └── src/app/
        ├── page.tsx           # Main page (login + todo UI)
        ├── providers.tsx      # Google OAuth provider
        └── layout.tsx         # Root layout
```

## Setup & Run

### 1. Backend (Django)

```bash
cd backend
pip install django djangorestframework django-cors-headers djangorestframework-simplejwt google-auth requests
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000
```

### 2. Flutter App (Mobile)

```bash
cd todo_app
flutter pub get
flutter run
```

> Update `apiBase` in `lib/main.dart` to match your setup:
> - Android Emulator: `http://10.0.2.2:8000`
> - Real phone (same WiFi): `http://YOUR_PC_IP:8000`

### 3. Next.js Frontend (Web)

```bash
cd nextjs-frontend
npm install
npm run dev
```

Open `http://localhost:3000` in your browser.

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/google/` | No | Google login (returns JWT) |
| GET | `/api/auth/me/` | JWT | Get current user info |
| GET | `/api/todos/` | JWT | List user's todos |
| POST | `/api/todos/` | JWT | Create a new todo |
| PUT | `/api/todos/<id>/` | JWT | Update a todo |
| DELETE | `/api/todos/<id>/` | JWT | Delete a todo |

## Google OAuth Setup

To enable Google Sign-In, you need OAuth 2.0 credentials from [Google Cloud Console](https://console.cloud.google.com/):

1. Create a project in Google Cloud Console
2. Enable the **Google Identity** API
3. Create OAuth 2.0 credentials:
   - **Web application** client (for Next.js)
   - **Android** client (for Flutter) — requires your app's SHA-1 fingerprint

Get your debug SHA-1 with:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```
