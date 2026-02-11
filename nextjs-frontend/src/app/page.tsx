"use client";

import { useState, useEffect } from "react";

// ============================================================
// API URL — same Django backend your Flutter app uses
// ============================================================
const API_URL = "http://127.0.0.1:8000/api/todos/";

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

export default function Home() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTodo, setNewTodo] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState<"all" | "active" | "completed">("all");

  // Fetch all todos from Django
  useEffect(() => {
    fetchTodos();
  }, []);

  async function fetchTodos() {
    try {
      const res = await fetch(API_URL);
      const data = await res.json();
      setTodos(data);
      setError("");
    } catch {
      setError("Cannot connect to server. Is Django running?");
    } finally {
      setLoading(false);
    }
  }

  // Add a new todo
  async function addTodo(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!newTodo.trim()) return;

    try {
      await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: newTodo.trim(), completed: false }),
      });
      setNewTodo("");
      fetchTodos();
    } catch {
      setError("Failed to add todo");
    }
  }

  // Toggle completed
  async function toggleTodo(todo: Todo) {
    try {
      await fetch(`${API_URL}${todo.id}/`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: todo.title, completed: !todo.completed }),
      });
      fetchTodos();
    } catch {
      setError("Failed to update todo");
    }
  }

  // Delete a todo
  async function deleteTodo(id: number) {
    try {
      await fetch(`${API_URL}${id}/`, { method: "DELETE" });
      fetchTodos();
    } catch {
      setError("Failed to delete todo");
    }
  }

  // Filter todos
  const filteredTodos = todos.filter((todo) => {
    if (filter === "active") return !todo.completed;
    if (filter === "completed") return todo.completed;
    return true;
  });

  const completedCount = todos.filter((t) => t.completed).length;
  const activeCount = todos.length - completedCount;

  return (
    <div className="min-h-screen bg-linear-to-br from-indigo-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-linear-to-r from-indigo-600 to-purple-600 shadow-lg">
        <div className="mx-auto max-w-2xl px-6 py-10">
          <h1 className="text-4xl font-bold text-white tracking-tight">
            My Todos
          </h1>
          <p className="mt-2 text-indigo-200 text-sm">
            Django + Next.js + Tailwind CSS
          </p>
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
                  <span className="ml-1.5 text-xs opacity-75">
                    {activeCount}
                  </span>
                )}
                {f === "completed" && completedCount > 0 && (
                  <span className="ml-1.5 text-xs opacity-75">
                    {completedCount}
                  </span>
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
                {/* Checkbox */}
                <button
                  onClick={() => toggleTodo(todo)}
                  className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 transition-all ${
                    todo.completed
                      ? "border-indigo-500 bg-indigo-500"
                      : "border-gray-300 hover:border-indigo-400"
                  }`}
                >
                  {todo.completed && (
                    <svg
                      className="h-3.5 w-3.5 text-white"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={3}
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  )}
                </button>

                {/* Title */}
                <span
                  onClick={() => toggleTodo(todo)}
                  className={`flex-1 cursor-pointer text-base transition-all ${
                    todo.completed
                      ? "text-gray-400 line-through"
                      : "text-gray-800"
                  }`}
                >
                  {todo.title}
                </span>

                {/* Delete Button */}
                <button
                  onClick={() => deleteTodo(todo.id)}
                  className="rounded-lg p-1.5 text-gray-300 opacity-0 transition-all hover:bg-red-50 hover:text-red-500 group-hover:opacity-100"
                >
                  <svg
                    className="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={1.5}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                    />
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
              <span>
                {completedCount}/{todos.length} completed
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-gray-100">
              <div
                className="h-full rounded-full bg-linear-to-r from-indigo-500 to-purple-500 transition-all duration-500"
                style={{
                  width: `${(completedCount / todos.length) * 100}%`,
                }}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
