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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        fontFamily: 'Roboto',
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
  String filter = 'all'; // 'all', 'active', 'completed'

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  // ---------- API CALLS ----------

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

  Future<void> addTodo(String title) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'completed': false}),
      );
      if (response.statusCode == 201) {
        _controller.clear();
        fetchTodos();
      }
    } catch (e) {
      _showError('Failed to add todo');
    }
  }

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
      fetchTodos();
    } catch (e) {
      _showError('Failed to update todo');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl$id/'));
      fetchTodos();
    } catch (e) {
      _showError('Failed to delete todo');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------- HELPERS ----------

  List<Map<String, dynamic>> get filteredTodos {
    if (filter == 'active') return todos.where((t) => !t['completed']).toList();
    if (filter == 'completed') return todos.where((t) => t['completed']).toList();
    return todos;
  }

  int get completedCount => todos.where((t) => t['completed']).length;
  int get activeCount => todos.length - completedCount;

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF), // light purple-ish bg
      body: Column(
        children: [
          // ===== GRADIENT HEADER =====
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Todos',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Django + Flutter',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== BODY (scrollable) =====
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: RefreshIndicator(
                onRefresh: fetchTodos,
                color: const Color(0xFF6366F1),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // ===== ADD TODO INPUT =====
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'What needs to be done?',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) addTodo(value.trim());
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (_controller.text.trim().isNotEmpty) {
                                    addTodo(_controller.text.trim());
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== FILTER TABS + ITEM COUNT =====
                    Row(
                      children: [
                        // Filter chips
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all', null),
                              _buildFilterChip('Active', 'active', activeCount),
                              _buildFilterChip('Completed', 'completed', completedCount),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Item count
                        Text(
                          '${todos.length} ${todos.length == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ===== TODO LIST =====
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF6366F1),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading todos...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredTodos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                filter == 'completed' ? '🎯' : '✨',
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                filter == 'all'
                                    ? 'No todos yet. Add one above!'
                                    : filter == 'active'
                                        ? 'All done! Nothing active.'
                                        : 'No completed todos yet.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredTodos.map((todo) => _buildTodoCard(todo)),

                    // ===== PROGRESS BAR =====
                    if (todos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            '$completedCount/${todos.length} completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              // Background
                              Container(color: Colors.grey.shade100),
                              // Fill
                              FractionallySizedBox(
                                widthFactor: todos.isEmpty
                                    ? 0
                                    : completedCount / todos.length,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF9333EA),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FILTER CHIP WIDGET =====
  Widget _buildFilterChip(String label, String value, int? count) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== TODO CARD WIDGET =====
  Widget _buildTodoCard(Map<String, dynamic> todo) {
    final bool completed = todo['completed'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Custom circular checkbox
                GestureDetector(
                  onTap: () => toggleTodo(todo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                      border: Border.all(
                        color: completed
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: completed
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: GestureDetector(
                    onTap: () => toggleTodo(todo),
                    child: Text(
                      todo['title'],
                      style: TextStyle(
                        fontSize: 15,
                        color: completed
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: () => deleteTodo(todo['id']),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
