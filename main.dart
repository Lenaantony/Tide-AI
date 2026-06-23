import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TideApp());
}

class TideColors {
  static const primary = Color(0xff021d46);
  static const ink = Color(0xFFFFFFFF);
  static const inkMuted = Color(0xff559cf9);

  static const surface = Color(0xff021d49);
  static const card = Color(0xff2753e5);
  static const border = Color(0xFF1B355A);

  static const priHigh = Color(0xFFFF6B6B);
  static const priMed = Color(0xFFFFC857);
  static const priLow = Color(0xFF6BCB77);
}

class TideSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}

class Task {
  final String title;
  final String priority;
  final String category;
  bool isDone;

  Task({
    required this.title,
    required this.category,
    this.priority = 'med',
    this.isDone = false,
  });

  Color get priorityColor {
    if (priority == 'high') return TideColors.priHigh;
    if (priority == 'low') return TideColors.priLow;
    return TideColors.priMed;
  }

  Color get categoryColor {
    switch (category.trim()) {
      case 'Work':
        return Colors.blue;
      case 'Personal':
        return Colors.green;
      case 'Study':
        return Colors.orange;
      case 'Health':
        return Colors.red;
      case 'Finance':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priority': priority,
      'category': category,
      'isDone': isDone,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      priority: json['priority'],
      category: json['category'],
      isDone: json['isDone'],
    );
  }
}

class TideApp extends StatelessWidget {
  const TideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tide',
      theme: ThemeData(
        scaffoldBackgroundColor: TideColors.surface,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? const AuthScreen()
          : const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  List<Task> tasks = [
    Task(
      title: 'Submit DBMS assignment',
      priority: 'high',
      category: 'Study',
    ),
    Task(
      title: 'Call Amma 6 PM',
      category: 'Personal',
    ),
    Task(
      title: 'Gym - leg day',
      priority: 'low',
      category: 'Personal',
    ),
    Task(
      title: 'Review Figma prototype',
      category: 'Work',
      isDone: true,
    ),
  ];
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTasks();
    });
  }

  void deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });

    saveTasks();
  }

  void toggleTask(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });

    saveTasks();
  }

  Future<void> _addTask(
    String title,
    String priority,
    String category,
  ) async {
    if (title.trim().isEmpty) return;

    String finalCategory = category;

    try {
      final aiCategory = await GeminiService.categorizeTask(title);
      finalCategory = aiCategory;
    } catch (e) {
      print("AI failed, using manual category: $e");
    }

    setState(() {
      tasks.add(
        Task(
          title: title.trim(),
          priority: priority,
          category: finalCategory,
        ),
      );
    });

    saveTasks();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final taskList = tasks.map((task) => jsonEncode(task.toJson())).toList();

    await prefs.setStringList('tasks', taskList);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final taskList = prefs.getStringList('tasks');

    if (taskList != null) {
      setState(() {
        tasks =
            taskList.map((item) => Task.fromJson(jsonDecode(item))).toList();
      });
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TideColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddTaskSheet(onAdd: _addTask),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = tasks.where((t) => !t.isDone).length;
    final filteredTasks = tasks.where((task) {
      final categoryMatch =
          selectedCategory == 'All' || task.category == selectedCategory;

      final searchMatch = task.title.toLowerCase().contains(searchQuery);

      return categoryMatch && searchMatch;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TideColors.surface,
        title: const Text('Tide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () async {
              final queryController = TextEditingController();

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Ask AI"),
                    content: TextField(
                      controller: queryController,
                      decoration: const InputDecoration(
                        hintText: "e.g. What should I do this weekend?",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          final query = queryController.text;

                          final result = await GeminiService.searchTasks(
                            query,
                            tasks,
                          );

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: TideColors.card,
                            builder: (_) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: ListView(
                                  children: result.map((t) {
                                    return ListTile(
                                      title: Text(
                                        t.title,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        t.category,
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                        child: const Text("Search"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good evening',
                  style: TextStyle(fontSize: 14, color: TideColors.inkMuted)),
              const SizedBox(height: 4),
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text('$remaining task${remaining == 1 ? "" : "s"}remaining',
                  style: const TextStyle(
                      fontSize: 14, color: TideColors.inkMuted)),
              const SizedBox(height: 24),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: TideColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['All', 'Work', 'Personal', 'Study'].map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        selectedColor: TideColors.primary,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: filteredTasks
                      .map((t) => TaskCard(
                            task: t,
                            onTap: () => toggleTask(t),
                            onDelete: () => deleteTask(t),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 10,
        onPressed: _openAddSheet,
        backgroundColor: TideColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TideColors.card,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TideColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TideColors.primary, width: 2),
                color: task.isDone ? TideColors.priLow : Colors.transparent,
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: task.isDone ? TideColors.inkMuted : TideColors.ink,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: task.categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: task.categoryColor,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        color: task.categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.priorityColor,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20,
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

class AddTaskSheet extends StatefulWidget {
  final void Function(String, String, String) onAdd;
  const AddTaskSheet({super.key, required this.onAdd});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _controller = TextEditingController();

  String _priority = 'med';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'What needs doing?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ['high', 'med', 'low'].map((p) {
              final selected = _priority == p;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p.toUpperCase()),
                  selected: selected,
                  selectedColor: TideColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : TideColors.inkMuted,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _priority = p;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TideColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                widget.onAdd(
                  _controller.text,
                  _priority,
                  'Study', // temporary fallback (AI overrides anyway)
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Save Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
