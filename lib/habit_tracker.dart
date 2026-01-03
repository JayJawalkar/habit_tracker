import 'package:flutter/material.dart';
import 'package:habit_tracker/calorie_chart_screen.dart';
import 'package:habit_tracker/yearly_heatmap_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// Auth Gate - Checks authentication state
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return session != null ? const MainNavigationScreen() : const AuthScreen();
  }
}

// Authentication Screen
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email for verification link!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.track_changes,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Habit Tracker',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Welcome back!' : 'Create your account',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                    },
                    child: Text(
                      _isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Sign In',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Main Navigation Screen
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const CalorieChartScreen(),
    const YearlyHeatmapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Calorie Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Yearly View',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List<HabitType> habitTypes = [];
  Map<String, List<HabitEntry>> weeklyHabits = {};
  List<CalorieEntry> calorieEntries = [];
  bool isLoading = true;
  final TextEditingController calorieController = TextEditingController();
  final TextEditingController mealController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get userId => supabase.auth.currentUser!.id;

  // Helper method to get IconData from code
  static IconData getIconData(int codePoint) {
    // Map of common icon codes to their IconData
    const iconMap = {
      0xe1ce: Icons.fitness_center,
      0xef3b: Icons.water_drop,
      0xef44: Icons.self_improvement,
      0xe0bb: Icons.book,
      0xe3c2: Icons.bedtime,
      0xe566: Icons.directions_run,
      0xe561: Icons.restaurant_menu,
      0xea30: Icons.sports_basketball,
      0xe3a1: Icons.music_note,
      0xe3ae: Icons.brush,
      0xe86f: Icons.code,
      0xe8cc: Icons.science,
      0xe91d: Icons.pets,
      0xe549: Icons.local_cafe,
      0xe7f2: Icons.emoji_emotions,
      0xe5cd: Icons.check,
      0xe86c: Icons.check_circle,
    };

    return iconMap[codePoint] ?? Icons.check_circle;
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadHabitTypes(),
      _loadWeeklyHabits(),
      _loadCalorieData(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadHabitTypes() async {
    try {
      final response = await supabase
          .from('habit_types')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      setState(() {
        habitTypes = (response as List)
            .map((item) => HabitType.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading habit types: $e');
    }
  }

  Future<void> _loadWeeklyHabits() async {
    try {
      final startOfWeek = _getStartOfWeek(DateTime.now());
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final response = await supabase
          .from('habits')
          .select()
          .eq('user_id', userId)
          .gte('date', DateFormat('yyyy-MM-dd').format(startOfWeek))
          .lte('date', DateFormat('yyyy-MM-dd').format(endOfWeek))
          .order('created_at', ascending: false);

      final Map<String, List<HabitEntry>> grouped = {};
      for (var item in response) {
        final habit = HabitEntry.fromJson(item);
        if (!grouped.containsKey(habit.date)) {
          grouped[habit.date] = [];
        }
        grouped[habit.date]!.add(habit);
      }

      setState(() => weeklyHabits = grouped);
    } catch (e) {
      debugPrint('Error loading weekly habits: $e');
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadCalorieData() async {
    try {
      final response = await supabase
          .from('calories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        calorieEntries = (response as List)
            .map((item) => CalorieEntry.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading calories: $e');
    }
  }

  Future<void> _addHabitType(String name, int iconCode, Color color) async {
    try {
      // Store color as hex string instead of integer to avoid overflow
      final colorHex = color.value.toRadixString(16).padLeft(8, '0');
      await supabase.from('habit_types').insert({
        'user_id': userId,
        'name': name,
        'icon_code': iconCode,
        'color_hex': colorHex,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadHabitTypes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habit "$name" added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteHabitType(int id) async {
    try {
      await supabase.from('habit_types').delete().eq('id', id);
      await _loadHabitTypes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Habit type deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markHabitComplete(int habitTypeId, String habitName) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await supabase.from('habits').insert({
        'date': today,
        'habit_type_id': habitTypeId,
        'habit_name': habitName,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadWeeklyHabits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$habitName completed!'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteHabit(int habitId) async {
    try {
      await supabase.from('habits').delete().eq('id', habitId);
      await _loadWeeklyHabits();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit removed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddHabitTypeDialog() {
    final nameController = TextEditingController();
    int selectedIconCode = Icons.check_circle.codePoint;
    Color selectedColor = Colors.green;

    const icons = [
      Icons.fitness_center,
      Icons.water_drop,
      Icons.self_improvement,
      Icons.book,
      Icons.bedtime,
      Icons.directions_run,
      Icons.restaurant_menu,
      Icons.sports_basketball,
      Icons.music_note,
      Icons.brush,
      Icons.code,
      Icons.science,
      Icons.pets,
      Icons.local_cafe,
      Icons.emoji_emotions,
    ];

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Habit Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    return InkWell(
                      onTap: () => setDialogState(
                        () => selectedIconCode = icon.codePoint,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIconCode == icon.codePoint
                              ? selectedColor.withAlpha(78)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIconCode == icon.codePoint
                                ? selectedColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, size: 28),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Color:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _addHabitType(
                    nameController.text.trim(),
                    selectedIconCode,
                    selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkHabitDialog() {
    if (habitTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add some habits first!'),
          action: SnackBarAction(
            label: 'Add',
            onPressed: () {
              _showAddHabitTypeDialog();
            },
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Habit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: habitTypes.map((habit) {
              return ListTile(
                leading: Icon(getIconData(habit.iconCode), color: habit.color),
                title: Text(habit.name),
                onTap: () {
                  Navigator.pop(context);
                  _markHabitComplete(habit.id, habit.name);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _addCalorieEntry() async {
    final calories = int.tryParse(calorieController.text);
    final meal = mealController.text.trim();

    if (calories == null || meal.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter valid data')));
      return;
    }

    try {
      await supabase.from('calories').insert({
        'calories': calories,
        'meal_name': meal,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      calorieController.clear();
      mealController.clear();
      await _loadCalorieData();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddCalorieDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Calorie Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: mealController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calorieController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addCalorieEntry, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showAddHabitTypeDialog,
            tooltip: 'Add New Habit Type',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMyHabitsSection(),
                  const SizedBox(height: 16),
                  _buildWeeklyProgressSection(),
                  const SizedBox(height: 32),
                  _buildCalorieSection(),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'habit',
            onPressed: _showMarkHabitDialog,
            child: const Icon(Icons.check_circle),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'calorie',
            onPressed: _showAddCalorieDialog,
            child: const Icon(Icons.restaurant),
          ),
        ],
      ),
    );
  }

  Widget _buildMyHabitsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Habits',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${habitTypes.length} habits',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (habitTypes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'No habits yet!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddHabitTypeDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Habit'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: habitTypes.map((habit) {
                  return GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Habit'),
                          content: Text('Delete "${habit.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteHabitType(habit.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Chip(
                      avatar: Icon(getIconData(habit.iconCode), size: 20),
                      label: Text(habit.name),
                      backgroundColor: habit.color.withAlpha(46),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressSection() {
    final startOfWeek = _getStartOfWeek(DateTime.now());
    final weekDays = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );
    final today = DateTime.now();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...weekDays.map((day) {
              final dateStr = DateFormat('yyyy-MM-dd').format(day);
              final dayHabits = weeklyHabits[dateStr] ?? [];
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? Colors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('EEE, MMM d').format(day),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isToday ? Colors.green[700] : null,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: dayHabits.isEmpty
                                ? Colors.grey[300]
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dayHabits.length}/${habitTypes.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dayHabits.isEmpty
                                  ? Colors.grey[700]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dayHabits.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: dayHabits.map((habit) {
                          final habitType = habitTypes.firstWhere(
                            (h) => h.id == habit.habitTypeId,
                            orElse: () => HabitType(
                              id: 0,
                              name: habit.habitName,
                              iconCode: Icons.check.codePoint,
                              colorHex: Colors.grey.value
                                  .toRadixString(16)
                                  .padLeft(8, '0'),
                              userId: userId,
                              createdAt: '',
                            ),
                          );
                          return Chip(
                            avatar: Icon(
                              getIconData(habitType.iconCode),
                              size: 16,
                            ),
                            label: Text(
                              habit.habitName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: habitType.color.withAlpha(45),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _deleteHabit(habit.id),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieSection() {
    final today = calorieEntries.where((e) {
      final entryDate = DateTime.parse(e.createdAt);
      final now = DateTime.now();
      return entryDate.year == now.year &&
          entryDate.month == now.month &&
          entryDate.day == now.day;
    }).toList();

    final totalToday = today.fold<int>(0, (sum, e) => sum + e.calories);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calorie Tracking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$totalToday kcal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Entries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...calorieEntries
                .take(10)
                .map((entry) => _buildCalorieEntry(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieEntry(CalorieEntry entry) {
    final date = DateTime.parse(entry.createdAt);
    final formatted = DateFormat('MMM dd, HH:mm').format(date);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: const Icon(Icons.restaurant, size: 20),
      ),
      title: Text(entry.mealName),
      subtitle: Text(formatted),
      trailing: Text(
        '${entry.calories} kcal',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    calorieController.dispose();
    mealController.dispose();
    super.dispose();
  }
}

class HabitType {
  final int id;
  final String name;
  final int iconCode;
  final String colorHex;
  final String userId;
  final String createdAt;

  HabitType({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.userId,
    required this.createdAt,
  });

  Color get color => Color(int.parse(colorHex, radix: 16));

  factory HabitType.fromJson(Map<String, dynamic> json) {
    return HabitType(
      id: json['id'] as int,
      name: json['name'] as String,
      iconCode: json['icon_code'] as int,
      colorHex: json['color_hex'] as String,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class HabitEntry {
  final int id;
  final int habitTypeId;
  final String habitName;
  final String date;
  final String createdAt;

  HabitEntry({
    required this.id,
    required this.habitTypeId,
    required this.habitName,
    required this.date,
    required this.createdAt,
  });

  factory HabitEntry.fromJson(Map<String, dynamic> json) {
    return HabitEntry(
      id: json['id'] as int,
      habitTypeId: json['habit_type_id'] as int,
      habitName: json['habit_name'] as String,
      date: json['date'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class CalorieEntry {
  final int id;
  final int calories;
  final String mealName;
  final String createdAt;

  CalorieEntry({
    required this.id,
    required this.calories,
    required this.mealName,
    required this.createdAt,
  });

  factory CalorieEntry.fromJson(Map<String, dynamic> json) {
    return CalorieEntry(
      id: json['id'] as int,
      calories: json['calories'] as int,
      mealName: json['meal_name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
