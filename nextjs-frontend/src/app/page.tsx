"use client";

import { useState, useEffect, useCallback } from "react";
import { useGoogleLogin } from "@react-oauth/google";

const API_BASE = "http://127.0.0.1:8000";
const TODOS_URL = `${API_BASE}/api/todos/`;
const GOOGLE_AUTH_URL = `${API_BASE}/api/auth/google/`;

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

interface UserInfo {
  name: string;
  email: string;
  picture: string;
}

export default function Home() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTodo, setNewTodo] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState<"all" | "active" | "completed">("all");

  // Auth state
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<UserInfo | null>(null);
  const [authLoading, setAuthLoading] = useState(true);

  // Check for saved token on mount
  useEffect(() => {
    const savedToken = localStorage.getItem("access_token");
    const savedUser = localStorage.getItem("user_info");
    if (savedToken && savedUser) {
      setToken(savedToken);
      setUser(JSON.parse(savedUser));
    }
    setAuthLoading(false);
  }, []);

  // Auth headers
  const authHeaders = useCallback(
    (): HeadersInit => ({
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    }),
    [token]
  );

  // Fetch todos when token is available
  useEffect(() => {
    if (token) fetchTodos();
  }, [token]);

  async function fetchTodos() {
    try {
      const res = await fetch(TODOS_URL, { headers: authHeaders() });
      if (res.status === 401) {
        logout();
        return;
      }
      const data = await res.json();
      setTodos(data);
      setError("");
    } catch {
      setError("Cannot connect to server. Is Django running?");
    } finally {
      setLoading(false);
    }
  }

  async function addTodo(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!newTodo.trim()) return;
    try {
      await fetch(TODOS_URL, {
        method: "POST",
        headers: authHeaders(),
        body: JSON.stringify({ title: newTodo.trim(), completed: false }),
      });
      setNewTodo("");
      fetchTodos();
    } catch {
      setError("Failed to add todo");
    }
  }

  async function toggleTodo(todo: Todo) {
    try {
      await fetch(`${TODOS_URL}${todo.id}/`, {
        method: "PUT",
        headers: authHeaders(),
        body: JSON.stringify({ title: todo.title, completed: !todo.completed }),
      });
      fetchTodos();
    } catch {
      setError("Failed to update todo");
    }
  }

  async function deleteTodo(id: number) {
    try {
      await fetch(`${TODOS_URL}${id}/`, {
        method: "DELETE",
        headers: authHeaders(),
      });
      fetchTodos();
    } catch {
      setError("Failed to delete todo");
    }
  }

  // Google Login — gets an authorization code, exchanges for ID token
  const googleLogin = useGoogleLogin({
    flow: "implicit",
    onSuccess: async (tokenResponse) => {
      try {
        // Get the user's ID token by calling Google's userinfo endpoint
        // then send the access_token to our backend which will verify it
        const userInfoRes = await fetch(
          "https://www.googleapis.com/oauth2/v3/userinfo",
          { headers: { Authorization: `Bearer ${tokenResponse.access_token}` } }
        );
        const userInfo = await userInfoRes.json();

        // For implicit flow, we send the access_token to our backend
        // Our backend needs to handle this — let's use the id_token from tokenResponse
        // Since implicit flow doesn't give id_token directly, we'll send access_token
        // and the backend will use it to verify via Google's tokeninfo endpoint
        const res = await fetch(GOOGLE_AUTH_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token: tokenResponse.access_token }),
        });

        if (res.ok) {
          const data = await res.json();
          const accessToken = data.access;
          const userData: UserInfo = data.user;

          localStorage.setItem("access_token", accessToken);
          localStorage.setItem("user_info", JSON.stringify(userData));
          setToken(accessToken);
          setUser(userData);
        } else {
          const errData = await res.json();
          setError(`Login failed: ${errData.error || "Unknown error"}`);
        }
      } catch {
        setError("Login failed. Please try again.");
      }
    },
    onError: () => setError("Google login failed"),
  });

  function logout() {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    localStorage.removeItem("user_info");
    setToken(null);
    setUser(null);
    setTodos([]);
    setLoading(true);
  }

  const filteredTodos = todos.filter((todo) => {
    if (filter === "active") return !todo.completed;
    if (filter === "completed") return todo.completed;
    return true;
  });

  const completedCount = todos.filter((t) => t.completed).length;
  const activeCount = todos.length - completedCount;

  // ===== AUTH LOADING =====
  if (authLoading) {
    return (
      <div className="min-h-screen bg-linear-to-br from-indigo-50 via-white to-purple-50 flex items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-indigo-200 border-t-indigo-500" />
      </div>
    );
  }

  // ===== LOGIN SCREEN =====
  if (!token) {
    return (
      <div className="min-h-screen bg-linear-to-br from-indigo-50 via-white to-purple-50 flex items-center justify-center">
        <div className="text-center px-6">
          <div className="mx-auto mb-8 flex h-24 w-24 items-center justify-center rounded-3xl bg-linear-to-br from-indigo-500 to-purple-500 shadow-xl shadow-indigo-200">
            <svg className="h-12 w-12 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-4xl font-bold text-gray-800 tracking-tight mb-2">My Todos</h1>
          <p className="text-gray-500 mb-10">Sign in to manage your tasks</p>

          {error && (
            <div className="mb-6 rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm">
              {error}
            </div>
          )}

          <button
            onClick={() => googleLogin()}
            className="inline-flex items-center gap-3 rounded-2xl bg-white px-8 py-4 text-gray-700 font-semibold shadow-lg ring-1 ring-black/5 hover:shadow-xl hover:-translate-y-0.5 transition-all"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" />
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
            </svg>
            Sign in with Google
          </button>
        </div>
      </div>
    );
  }

  // ===== MAIN APP (authenticated) =====
  return (
    <div className="min-h-screen bg-linear-to-br from-indigo-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-linear-to-r from-indigo-600 to-purple-600 shadow-lg">
        <div className="mx-auto max-w-2xl px-6 py-10">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-bold text-white tracking-tight">
                My Todos
              </h1>
              <p className="mt-2 text-indigo-200 text-sm">
                {user?.name || user?.email}
              </p>
            </div>
            <div className="flex items-center gap-3">
              {user?.picture && (
                <img
                  src={user.picture}
                  alt=""
                  className="h-10 w-10 rounded-full ring-2 ring-white/30"
                />
              )}
              <button
                onClick={logout}
                className="rounded-xl bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/20 transition-all"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-2xl px-6 -mt-6">
        {/* Error Banner */}
        {error && (
          <div className="mb-4 rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm shadow-sm">
            {error}
          </div>
        )}

        {/* Add Todo Form */}
        <form onSubmit={addTodo} className="mb-6">
          <div className="flex gap-3 rounded-2xl bg-white p-2 shadow-lg shadow-indigo-100/50 ring-1 ring-black/5">
            <input
              type="text"
              value={newTodo}
              onChange={(e) => setNewTodo(e.target.value)}
              placeholder="What needs to be done?"
              className="flex-1 rounded-xl bg-gray-50 px-4 py-3 text-gray-800 placeholder-gray-400 outline-none focus:bg-white focus:ring-2 focus:ring-indigo-500/20 transition-all"
            />
            <button
              type="submit"
              className="rounded-xl bg-linear-to-r from-indigo-500 to-purple-500 px-6 py-3 font-semibold text-white shadow-md hover:shadow-lg hover:from-indigo-600 hover:to-purple-600 active:scale-[0.98] transition-all"
            >
              Add
            </button>
          </div>
        </form>

        {/* Filter Tabs */}
        <div className="mb-4 flex items-center justify-between">
          <div className="flex gap-1 rounded-xl bg-white p-1 shadow-sm ring-1 ring-black/5">
            {(["all", "active", "completed"] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`rounded-lg px-4 py-1.5 text-sm font-medium transition-all ${
                  filter === f
                    ? "bg-indigo-500 text-white shadow-sm"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
                {f === "active" && activeCount > 0 && (
                  <span className="ml-1.5 text-xs opacity-75">{activeCount}</span>
                )}
                {f === "completed" && completedCount > 0 && (
                  <span className="ml-1.5 text-xs opacity-75">{completedCount}</span>
                )}
              </button>
            ))}
          </div>
          <span className="text-sm text-gray-400">
            {todos.length} {todos.length === 1 ? "item" : "items"}
          </span>
        </div>

        {/* Todo List */}
        <div className="space-y-2">
          {loading ? (
            <div className="py-16 text-center text-gray-400">
              <div className="mx-auto mb-3 h-8 w-8 animate-spin rounded-full border-4 border-indigo-200 border-t-indigo-500" />
              Loading todos...
            </div>
          ) : filteredTodos.length === 0 ? (
            <div className="py-16 text-center">
              <div className="text-5xl mb-3">
                {filter === "completed" ? "🎯" : "✨"}
              </div>
              <p className="text-gray-400">
                {filter === "all"
                  ? "No todos yet. Add one above!"
                  : filter === "active"
                  ? "All done! Nothing active."
                  : "No completed todos yet."}
              </p>
            </div>
          ) : (
            filteredTodos.map((todo) => (
              <div
                key={todo.id}
                className={`group flex items-center gap-4 rounded-xl bg-white px-5 py-4 shadow-sm ring-1 ring-black/5 transition-all hover:shadow-md hover:-translate-y-0.5 ${
                  todo.completed ? "opacity-60" : ""
                }`}
              >
                <button
                  onClick={() => toggleTodo(todo)}
                  className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 transition-all ${
                    todo.completed
                      ? "border-indigo-500 bg-indigo-500"
                      : "border-gray-300 hover:border-indigo-400"
                  }`}
                >
                  {todo.completed && (
                    <svg className="h-3.5 w-3.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </button>
                <span
                  onClick={() => toggleTodo(todo)}
                  className={`flex-1 cursor-pointer text-base transition-all ${
                    todo.completed ? "text-gray-400 line-through" : "text-gray-800"
                  }`}
                >
                  {todo.title}
                </span>
                <button
                  onClick={() => deleteTodo(todo.id)}
                  className="rounded-lg p-1.5 text-gray-300 opacity-0 transition-all hover:bg-red-50 hover:text-red-500 group-hover:opacity-100"
                >
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            ))
          )}
        </div>

        {/* Progress Bar */}
        {todos.length > 0 && (
          <div className="mt-6 mb-10">
            <div className="flex items-center justify-between text-sm text-gray-400 mb-2">
              <span>Progress</span>
              <span>{completedCount}/{todos.length} completed</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-gray-100">
              <div
                className="h-full rounded-full bg-linear-to-r from-indigo-500 to-purple-500 transition-all duration-500"
                style={{ width: `${(completedCount / todos.length) * 100}%` }}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
