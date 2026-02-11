# TODO-APP

A full-stack Todo application with a **Django REST API** backend and three frontends: **Flutter** (mobile), **Next.js** (React + Tailwind), and a simple **HTML/JS** web page.

## Architecture

```
┌──────────────────────┐
│   Flutter (mobile)    │──── REST API ──┐
└──────────────────────┘                 │
                                         ▼
┌──────────────────────┐          ┌────────────┐
│   Next.js (React)     │── REST ──>│   Django   │
└──────────────────────┘          │  (SQLite)  │
                                   └────────────┘
┌──────────────────────┐                 ▲
│   HTML/JS (simple)    │──── REST ──────┘
└──────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Django 5 + Django REST Framework |
| Database | SQLite |
| Mobile Frontend | Flutter (Dart) |
| Web Frontend (Modern) | Next.js + React + Tailwind CSS |
| Web Frontend (Simple) | HTML, CSS, JavaScript |
| Communication | REST API (JSON) |

## Project Structure

```
TODO-APP/
├── backend/              # Django REST API
│   ├── backend/          # Project settings & URLs
│   ├── todos/            # Todo app (models, views, serializers)
│   └── db.sqlite3        # SQLite database
├── todo_app/             # Flutter mobile app
│   └── lib/main.dart     # App source code
├── nextjs-frontend/      # Next.js + React + Tailwind CSS
│   └── src/app/page.tsx  # Main page component
└── frontend/             # Simple HTML/JS web frontend
    └── index.html        # Single-file web app
```

## Features

- View list of todos
- Add new todo
- Mark todo as completed
- Delete todo
- Filter by All / Active / Completed (Next.js)
- Progress bar (Next.js)
- Real-time sync across all frontends (shared backend)

## Setup & Run

### 1. Backend (Django)

```bash
cd backend
pip install django djangorestframework django-cors-headers
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000
```

### 2. Flutter App (Mobile)

```bash
cd todo_app
flutter pub get
flutter run
```

> Update `baseUrl` in `lib/main.dart` to match your setup:
> - iOS Simulator: `http://127.0.0.1:8000/api/todos/`
> - Android Emulator: `http://10.0.2.2:8000/api/todos/`
> - Real phone (same WiFi): `http://YOUR_PC_IP:8000/api/todos/`

### 3. Next.js Frontend (Modern Web)

```bash
cd nextjs-frontend
npm install
npm run dev
```

Open `http://localhost:3000` in your browser.

### 4. Simple Web Frontend

Open `frontend/index.html` in your browser while Django is running.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos/` | List all todos |
| POST | `/api/todos/` | Create a new todo |
| PUT | `/api/todos/<id>/` | Update a todo |
| DELETE | `/api/todos/<id>/` | Delete a todo |
