import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// IMPORTANT: Change this URL depending on how you run the app
// ============================================================
// Running on a REAL phone or Android Emulator? Use your computer's IP:
//   const baseUrl = 'http://10.0.2.2:8000/api/todos/';  // Android Emulator
//   const baseUrl = 'http://YOUR_PC_IP:8000/api/todos/'; // Real phone
// Running on iOS Simulator or Chrome? localhost works:
//   const baseUrl = 'http://127.0.0.1:8000/api/todos/';
const baseUrl = 'http://192.168.100.42:8000/api/todos/';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> todos = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  // ---------- API CALLS ----------

  // GET all todos from Django
  Future<void> fetchTodos() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          todos = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Cannot connect to server. Is Django running?');
    }
  }

  // POST a new todo
  Future<void> addTodo(String title) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'completed': false}),
      );
      if (response.statusCode == 201) {
        _controller.clear();
        fetchTodos(); // refresh the list
      }
    } catch (e) {
      _showError('Failed to add todo');
    }
  }

  // PUT - toggle completed status
  Future<void> toggleTodo(Map<String, dynamic> todo) async {
    try {
      await http.put(
        Uri.parse('$baseUrl${todo['id']}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': todo['title'],
          'completed': !todo['completed'],
        }),
      );
      fetchTodos(); // refresh the list
    } catch (e) {
      _showError('Failed to update todo');
    }
  }

  // DELETE a todo
  Future<void> deleteTodo(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl$id/'));
      fetchTodos(); // refresh the list
    } catch (e) {
      _showError('Failed to delete todo');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // --- Input row: TextField + Add button ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new todo...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) addTodo(value.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      addTodo(_controller.text.trim());
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // --- Todo list ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : todos.isEmpty
                    ? const Center(child: Text('No todos yet. Add one!'))
                    : ListView.builder(
                        itemCount: todos.length,
                        itemBuilder: (context, index) {
                          final todo = todos[index];
                          return ListTile(
                            leading: Checkbox(
                              value: todo['completed'],
                              onChanged: (_) => toggleTodo(todo),
                            ),
                            title: Text(
                              todo['title'],
                              style: TextStyle(
                                decoration: todo['completed']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTodo(todo['id']),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
