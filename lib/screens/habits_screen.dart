import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Map<String, dynamic>> habitTypes = [];
  List<Map<String, dynamic>> habits = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load habit types
      final typesResponse = await Supabase.instance.client
          .from('habit_types')
          .select()
          .eq('user_id', user.id);

      // Load habits for the selected date
      final habitsResponse = await Supabase.instance.client
          .from('habits')
          .select()
          .eq('user_id', user.id)
          .eq('date', DateFormat('yyyy-MM-dd').format(selectedDate));

      setState(() {
        habitTypes = List<Map<String, dynamic>>.from(typesResponse);
        habits = List<Map<String, dynamic>>.from(habitsResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading habits: $e')));
      }
    }
  }

  Future<void> _toggleHabit(int habitTypeId, String habitName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final existing = habits.firstWhere(
        (h) => h['habit_type_id'] == habitTypeId && h['date'] == dateStr,
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        // Delete habit
        await Supabase.instance.client
            .from('habits')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add habit
        await Supabase.instance.client.from('habits').insert({
          'user_id': user.id,
          'habit_type_id': habitTypeId,
          'date': dateStr,
          'habit_name': habitName,
        });
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling habit: $e')));
      }
    }
  }

  Future<void> _addHabitType(String name, int iconCode, String colorHex) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('habit_types').insert({
        'user_id': user.id,
        'name': name,
        'icon_code': iconCode,
        'color_hex': colorHex,
      });

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding habit type: $e')));
      }
    }
  }

  bool isHabitCompleted(int habitTypeId) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return habits.any(
      (h) => h['habit_type_id'] == habitTypeId && h['date'] == dateStr,
    );
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHabitDialog(
        onAdd: (name, iconCode, color) async {
          await _addHabitType(name, iconCode, color);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayHabits = habits.where((h) {
      return h['date'] == DateFormat('yyyy-MM-dd').format(selectedDate);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'TODAY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.grey[600],
              ),
            ),
            Text(
              DateFormat('EEE, MMM d').format(selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'STREAK',
                          value: '12 Days',
                          icon: '🔥',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'TODAY',
                          value: '$todayHabits/${habitTypes.length}',
                          icon: '✓',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Habits List
                  const Text(
                    "Today's Habits",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ...habitTypes.map((habitType) {
                    final completed = isHabitCompleted(habitType['id']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHabitCard(habitType, completed),
                    );
                  }),

                  // Add Habit Button
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _showAddHabitDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      side: BorderSide(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Text('+ Add New Habit'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habitType, bool completed) {
    final color = Color(
      int.parse(habitType['color_hex'].replaceFirst('#', '0xFF'), radix: 16),
    );
    final icon = String.fromCharCode(habitType['icon_code']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? const Color(0xFF13ec80).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 24, color: color)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habitType['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '0 Days',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Week sparkline
                Row(
                  children: List.generate(7, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: index < 3
                            ? const Color(0xFF13ec80)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Checkbox
          GestureDetector(
            onTap: () => _toggleHabit(habitType['id'], habitType['name']),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF13ec80) : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: completed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF13ec80).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.check_rounded,
                color: completed ? Colors.black : Colors.grey[400],
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddHabitDialog extends StatefulWidget {
  final Function(String name, int iconCode, String color) onAdd;

  const AddHabitDialog({super.key, required this.onAdd});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _nameController = TextEditingController();
  int selectedIcon = 0x1F3CB; // 🏋
  String selectedColor = '#3b82f6';

  final icons = [
    {'code': 0x1F3CB, 'label': '🏋️'},
    {'code': 0x1F4A7, 'label': '💧'},
    {'code': 0x1F4D6, 'label': '📖'},
    {'code': 0x1F6AB, 'label': '🚫'},
    {'code': 0x1F3C3, 'label': '🏃'},
    {'code': 0x1F9D8, 'label': '🧘'},
    {'code': 0x1F4AA, 'label': '💪'},
    {'code': 0x1F34E, 'label': '🍎'},
  ];

  final colors = [
    '#3b82f6',
    '#10b981',
    '#f43f5e',
    '#f59e0b',
    '#8b5cf6',
    '#ec4899',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Habit',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Morning Run',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selection
            const Text(
              'Icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons.map((icon) {
                final isSelected = selectedIcon == icon['code'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => selectedIcon = icon['code'] as int),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF13ec80)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? const Color(0xFF13ec80).withOpacity(0.1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        icon['label'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color Selection
            const Text(
              'Color',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: colors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'), radix: 16)),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Color(
                                int.parse(color.replaceFirst('#', '0xFF')),
                              ),
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        widget.onAdd(
                          _nameController.text,
                          selectedIcon,
                          selectedColor,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13ec80),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
