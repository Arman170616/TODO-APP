# TODO-APP

A full-stack Todo application with a **Django REST API** backend and two frontends: **Flutter** (mobile) and **Web** (HTML/JS).

## Architecture

```
┌─────────────────┐
│  Flutter (phone) │──── REST API ──┐
└─────────────────┘                 │
                                    ▼
┌─────────────────┐          ┌────────────┐
│  Web (browser)   │── REST ──>│   Django   │
└─────────────────┘          │  (SQLite)  │
                              └────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Django 5 + Django REST Framework |
| Database | SQLite |
| Mobile Frontend | Flutter (Dart) |
| Web Frontend | HTML, CSS, JavaScript |
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
└── frontend/             # Web frontend
    └── index.html        # Single-file web app
```

## Features

- View list of todos
- Add new todo
- Mark todo as completed
- Delete todo
- Real-time sync between mobile and web (shared backend)

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

### 3. Web Frontend

Open `frontend/index.html` in your browser while Django is running.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos/` | List all todos |
| POST | `/api/todos/` | Create a new todo |
| PUT | `/api/todos/<id>/` | Update a todo |
| DELETE | `/api/todos/<id>/` | Delete a todo |
