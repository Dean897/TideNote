import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const TideNoteApp());
}

class TideNoteApp extends StatelessWidget {
  const TideNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TideNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F7F0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8DBEE1)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFabOpen = false;
  List<Map<String, dynamic>> _tasks = [];
  List<String> _folders = []; // Data Folder Dinamis

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData(); // Memuat tugas dan folder
  }

  // ==========================================
  // FUNGSI LOCAL STORAGE (TUGAS & FOLDER)
  // ==========================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTasks = prefs.getString('tidenote_data');
    final String? savedFolders = prefs.getString('tidenote_folders');

    // Muat Folder
    if (savedFolders != null) {
      setState(() {
        _folders = List<String>.from(json.decode(savedFolders));
      });
    } else {
      setState(() {
        _folders = ['Semester 8 - Tugas Akhir', 'Pekerjaan - UI/UX', 'Lainnya'];
      });
      _saveFolders();
    }

    // Muat Tugas
    if (savedTasks != null) {
      final List<dynamic> decodedData = json.decode(savedTasks);
      setState(() {
        _tasks = decodedData.map((item) {
          return {
            'id': item['id'],
            'title': item['title'],
            'instruction': item['instruction'],
            'deadline': DateTime.parse(item['deadline']),
            'status': item['status'],
            'isUrgent': item['isUrgent'],
            'folder': item['folder'],
          };
        }).toList();
      });
    } else {
      setState(() {
        _tasks = [
          {
            'id': '1',
            'title': 'Revisi Proposal Skripsi',
            'instruction': 'Perbaiki bab 2 sesuai arahan dosen pembimbing.',
            'deadline': DateTime.now().add(const Duration(hours: 12)),
            'status': 'To-Do',
            'isUrgent': true,
            'folder': 'Semester 8 - Tugas Akhir',
          },
          {
            'id': '2',
            'title': 'Desain Wireframe TideNote',
            'instruction': 'Gunakan bentuk squircle dan warna pastel blue.',
            'deadline': DateTime.now().add(const Duration(days: 1)),
            'status': 'In Progress',
            'isUrgent': false,
            'folder': 'Pekerjaan - UI/UX',
          },
        ];
      });
      _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> dataToSave = _tasks.map((task) {
      return {
        'id': task['id'],
        'title': task['title'],
        'instruction': task['instruction'],
        'deadline': task['deadline'].toIso8601String(),
        'status': task['status'],
        'isUrgent': task['isUrgent'],
        'folder': task['folder'],
      };
    }).toList();
    await prefs.setString('tidenote_data', json.encode(dataToSave));
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tidenote_folders', json.encode(_folders));
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task['id'] == id);
    });
    _saveTasks();
  }

  void _toggleTaskStatus(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
      if (taskIndex != -1) {
        final currentStatus = _tasks[taskIndex]['status'];
        if (currentStatus == 'To-Do') {
          _tasks[taskIndex]['status'] = 'In Progress';
        } else if (currentStatus == 'In Progress') {
          _tasks[taskIndex]['status'] = 'Done';
        } else {
          _tasks[taskIndex]['status'] = 'To-Do';
        }
      }
    });
    _saveTasks();
  }

  // ==========================================
  // MODAL TAMBAH FOLDER
  // ==========================================
  void _showAddFolderModal() {
    final TextEditingController folderController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Folder Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: folderController,
                decoration: InputDecoration(
                  labelText: 'Nama Folder',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DBEE1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final folderName = folderController.text.trim();
                    if (folderName.isEmpty) return;

                    setState(() {
                      if (!_folders.contains(folderName)) {
                        _folders.add(folderName);
                      }
                    });

                    _saveFolders();
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Simpan Folder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // MODAL TAMBAH TUGAS (Dengan Pilihan Folder)
  // ==========================================
  void _showAddTaskModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController instructionController = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));
    String selectedFolder = _folders.isNotEmpty ? _folders.first : 'Lainnya';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // StatefulBuilder digunakan agar Dropdown bisa merubah datanya sendiri di dalam modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Tugas Baru',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: instructionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Instruksi / Catatan',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Pilih Folder
                  DropdownButtonFormField<String>(
                    value: selectedFolder,
                    decoration: InputDecoration(
                      labelText: 'Pilih Folder',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _folders.map((String folder) {
                      return DropdownMenuItem<String>(
                        value: folder,
                        child: Text(
                          folder,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          selectedFolder = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8DBEE1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;

                        setState(() {
                          _tasks.add({
                            'id': DateTime.now().toString(),
                            'title': titleController.text,
                            'instruction': instructionController.text,
                            'deadline': selectedDeadline,
                            'status': 'To-Do',
                            'isUrgent': false,
                            'folder':
                                selectedFolder, // Menyimpan ke folder pilihan
                          });
                        });

                        _saveTasks();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Simpan Tugas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  List<Map<String, dynamic>> _getFilteredTasks(String folderName) {
    return _tasks.where((task) {
      bool matchesFolder = task['folder'] == folderName;
      bool matchesSearch =
          task['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (task['instruction'] != null &&
              task['instruction'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));
      bool matchesTab = _selectedTabIndex == 0
          ? task['status'] != 'Done'
          : task['status'] == 'Done';
      return matchesFolder && matchesSearch && matchesTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah seluruh tugas kosong di semua folder
    bool isListEmpty = true;
    for (String folder in _folders) {
      if (_getFilteredTasks(folder).isNotEmpty) {
        isListEmpty = false;
        break;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TideNote.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8DBEE1),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEE, dd MMM yyyy',
                              'id_ID',
                            ).format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF8DBEE1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari tugas atau instruksi...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFF8DBEE1)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Tugas Aktif',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 0
                                  ? const Color(0xFF8DBEE1)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFF8DBEE1)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Arsip Selesai',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 1
                                  ? const Color(0xFF8DBEE1)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: isListEmpty && _folders.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada tugas yang cocok dengan pencarian.'
                                  : _selectedTabIndex == 1
                                  ? 'Belum ada tugas yang selesai.'
                                  : 'Semua tugas sudah beres!',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: _folders.map((folderName) {
                              final folderTasks = _getFilteredTasks(folderName);
                              // Sembunyikan folder jika sedang mencari dan foldernya kosong
                              if (folderTasks.isEmpty &&
                                  _searchQuery.isNotEmpty) {
                                return const SizedBox.shrink();
                              }
                              return FolderAccordion(
                                folderName: folderName,
                                taskCount: folderTasks.length,
                                tasks: folderTasks
                                    .map(
                                      (t) => TaskCard.fromMap(
                                        t,
                                        onDelete: () => _deleteTask(t['id']),
                                        onToggleStatus: () =>
                                            _toggleTaskStatus(t['id']),
                                      ),
                                    )
                                    .toList(),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isFabOpen)
            GestureDetector(
              onTap: _toggleFab,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(color: Colors.white.withOpacity(0.4)),
              ),
            ),
          Positioned(
            bottom: 32,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabOpen)
                  _buildFabOption(
                    icon: Icons.create_new_folder_rounded,
                    label: 'Tambah Folder',
                    onTap: () {
                      _toggleFab();
                      _showAddFolderModal();
                    },
                  ),
                const SizedBox(height: 12),
                if (_isFabOpen)
                  _buildFabOption(
                    icon: Icons.task_alt_rounded,
                    label: 'Tambah Tugas',
                    isPrimary: true,
                    onTap: () {
                      _toggleFab();
                      _showAddTaskModal();
                    },
                  ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF8DBEE1),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: _toggleFab,
                  child: AnimatedRotation(
                    turns: _isFabOpen ? 0.125 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF8DBEE1) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF8DBEE1),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class FolderAccordion extends StatelessWidget {
  final String folderName;
  final int taskCount;
  final List<Widget> tasks;

  const FolderAccordion({
    super.key,
    required this.folderName,
    required this.taskCount,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFBFF4FF).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: Color(0xFF8DBEE1),
              size: 16,
            ),
          ),
          title: Text(
            folderName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$taskCount',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 8,
          ),
          children: tasks,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String id;
  final String title;
  final String? instruction;
  final DateTime deadline;
  final String status;
  final bool isUrgent;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const TaskCard({
    super.key,
    required this.id,
    required this.title,
    this.instruction,
    required this.deadline,
    required this.status,
    required this.isUrgent,
    required this.onDelete,
    required this.onToggleStatus,
  });

  factory TaskCard.fromMap(
    Map<String, dynamic> data, {
    required VoidCallback onDelete,
    required VoidCallback onToggleStatus,
  }) {
    return TaskCard(
      id: data['id'],
      title: data['title'],
      instruction: data['instruction'],
      deadline: data['deadline'],
      status: data['status'],
      isUrgent: data['isUrgent'],
      onDelete: onDelete,
      onToggleStatus: onToggleStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = status == 'Done';
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    Color deadlineColor = const Color(0xFF86EFAC);

    if (difference <= 1) {
      deadlineColor = const Color(0xFFFCA5A5);
    } else if (difference <= 2) {
      deadlineColor = const Color(0xFFFDE047);
    }

    String deadlineText = DateFormat('dd MMM, HH:mm').format(deadline);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDone ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? Colors.transparent : deadlineColor,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (instruction != null && instruction!.isNotEmpty)
                  Text(
                    instruction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                const SizedBox(height: 16),
                const Divider(
                  color: Color(0xFFF1F5F9),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          deadlineText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onToggleStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.green.shade50
                              : status == 'In Progress'
                              ? const Color(0xFFBFF4FF)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? Colors.green.shade600
                                : status == 'In Progress'
                                ? const Color(0xFF5AB2D3)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isUrgent && !isDone)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange.shade400,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
