import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================
// IMPORTANT: Change this URL depending on how you run the app
// ============================================================
const apiBase = 'http://192.168.100.42:8000';
const todosUrl = '$apiBase/api/todos/';
const googleAuthUrl = '$apiBase/api/auth/google/';

// Google Sign-In (use Web Client ID as serverClientId)
final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId:
      '140560791771-j78sejqcc5f3roeq0te6cput1fi6c062.apps.googleusercontent.com',
);

const _storage = FlutterSecureStorage();

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
      home: const AuthGate(),
    );
  }
}

// ===== AUTH GATE: checks if user is logged in =====
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  String? _token;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    final name = await _storage.read(key: 'user_name');
    final email = await _storage.read(key: 'user_email');
    final picture = await _storage.read(key: 'user_picture');
    if (token != null) {
      setState(() {
        _token = token;
        _userInfo = {'name': name ?? '', 'email': email ?? '', 'picture': picture ?? ''};
        _checking = false;
      });
    } else {
      setState(() => _checking = false);
    }
  }

  void _onLoggedIn(String token, Map<String, dynamic> user) {
    setState(() {
      _token = token;
      _userInfo = user;
    });
  }

  void _onLoggedOut() {
    setState(() {
      _token = null;
      _userInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F3FF),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    if (_token == null) {
      return LoginScreen(onLoggedIn: _onLoggedIn);
    }
    return TodoScreen(token: _token!, userInfo: _userInfo!, onLoggedOut: _onLoggedOut);
  }
}

// ===== LOGIN SCREEN =====
class LoginScreen extends StatefulWidget {
  final Function(String token, Map<String, dynamic> user) onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _loading = false);
        return; // user cancelled
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _showError('Failed to get Google token');
        setState(() => _loading = false);
        return;
      }

      // Send token to Django backend
      final response = await http.post(
        Uri.parse(googleAuthUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final user = data['user'] as Map<String, dynamic>;

        // Save to secure storage
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        await _storage.write(key: 'user_name', value: user['name'] ?? '');
        await _storage.write(key: 'user_email', value: user['email'] ?? '');
        await _storage.write(key: 'user_picture', value: user['picture'] ?? '');

        widget.onLoggedIn(accessToken, user);
      } else {
        _showError('Login failed: ${response.body}');
      }
    } catch (e) {
      _showError('Login error: $e');
    }
    setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'My Todos',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your tasks',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 48),
              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade800,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" logo
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'G',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== TODO SCREEN (authenticated) =====
class TodoScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userInfo;
  final VoidCallback onLoggedOut;

  const TodoScreen({
    super.key,
    required this.token,
    required this.userInfo,
    required this.onLoggedOut,
  });

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> todos = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = true;
  String filter = 'all';

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  // ---------- API CALLS (with JWT) ----------

  Future<void> fetchTodos() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(todosUrl),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          todos = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _logout();
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Cannot connect to server');
    }
  }

  Future<void> addTodo(String title) async {
    try {
      final response = await http.post(
        Uri.parse(todosUrl),
        headers: _authHeaders,
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
        Uri.parse('$todosUrl${todo['id']}/'),
        headers: _authHeaders,
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
      await http.delete(
        Uri.parse('$todosUrl$id/'),
        headers: _authHeaders,
      );
      fetchTodos();
    } catch (e) {
      _showError('Failed to delete todo');
    }
  }

  Future<void> _logout() async {
    await _googleSignIn.signOut();
    await _storage.deleteAll();
    widget.onLoggedOut();
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
    final userName = widget.userInfo['name'] ?? '';
    final userEmail = widget.userInfo['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
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
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 40),
                child: Row(
                  children: [
                    Expanded(
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
                          const SizedBox(height: 4),
                          Text(
                            userName.isNotEmpty ? userName : userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logout button
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      tooltip: 'Logout',
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
                        Text(
                          '${todos.length} ${todos.length == 1 ? 'item' : 'items'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
                              Text('Loading todos...', style: TextStyle(color: Colors.grey)),
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
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
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
                          Text('Progress',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                          Text('$completedCount/${todos.length} completed',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              Container(color: Colors.grey.shade100),
                              FractionallySizedBox(
                                widthFactor:
                                    todos.isEmpty ? 0 : completedCount / todos.length,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
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
                GestureDetector(
                  onTap: () => toggleTodo(todo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? const Color(0xFF6366F1) : Colors.transparent,
                      border: Border.all(
                        color: completed
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => toggleTodo(todo),
                    child: Text(
                      todo['title'],
                      style: TextStyle(
                        fontSize: 15,
                        color: completed ? Colors.grey.shade400 : Colors.grey.shade800,
                        decoration: completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
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
