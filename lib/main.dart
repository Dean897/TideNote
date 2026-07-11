import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart'; // Digunakan untuk format tanggal yang rapi

void main() {
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

  // ==========================================
  // STATE DINAMIS (DATABASE SEMENTARA)
  // ==========================================
  // Di sinilah tugas-tugas akan disimpan
  final List<Map<String, dynamic>> _tasks = [
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
    {
      'id': '3',
      'title': 'Belanja Bulanan',
      'instruction': 'Beli sabun, sampo, dan bahan makanan.',
      'deadline': DateTime.now().add(const Duration(days: 3)),
      'status': 'To-Do',
      'isUrgent': false,
      'folder': 'Lainnya',
    },
  ];

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  // ==========================================
  // FUNGSI MEMUNCULKAN FORM TAMBAH TUGAS
  // ==========================================
  void _showAddTaskModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController instructionController = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          // Memastikan form tidak tertutup keyboard
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

              // Input Judul
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

              // Input Instruksi
              TextField(
                controller: instructionController,
                maxLines: 3,
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
              const SizedBox(height: 24),

              // Tombol Simpan
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
                    // Validasi: Judul tidak boleh kosong
                    if (titleController.text.trim().isEmpty) return;

                    // Memasukkan data baru ke dalam list _tasks
                    setState(() {
                      _tasks.add({
                        'id': DateTime.now().toString(),
                        'title': titleController.text,
                        'instruction': instructionController.text,
                        'deadline': selectedDeadline, // Secara default besok
                        'status':
                            'To-Do', // Status otomatis To-Do sesuai rancanganmu
                        'isUrgent': false,
                        'folder': 'Lainnya',
                      });
                    });

                    Navigator.pop(ctx); // Menutup Modal Form
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
  }

  // ==========================================
  // PEMBANTU: FILTER DATA BERDASARKAN FOLDER
  // ==========================================
  List<Map<String, dynamic>> _getTasksByFolder(String folderName) {
    return _tasks.where((task) => task['folder'] == folderName).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Memecah tugas berdasarkan foldernya
    final folderSkripsi = _getTasksByFolder('Semester 8 - Tugas Akhir');
    final folderPekerjaan = _getTasksByFolder('Pekerjaan - UI/UX');
    final folderLainnya = _getTasksByFolder('Lainnya');

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
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
                            'Hari ini',
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

                  // --- SEARCH BAR ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
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

                  // --- DAFTAR FOLDER & TUGAS (DI-RENDER DINAMIS) ---
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Folder 1
                        if (folderSkripsi.isNotEmpty)
                          FolderAccordion(
                            folderName: 'Semester 8 - Tugas Akhir',
                            taskCount: folderSkripsi.length,
                            tasks: folderSkripsi
                                .map((t) => TaskCard.fromMap(t))
                                .toList(),
                          ),

                        // Folder 2
                        if (folderPekerjaan.isNotEmpty)
                          FolderAccordion(
                            folderName: 'Pekerjaan - UI/UX',
                            taskCount: folderPekerjaan.length,
                            tasks: folderPekerjaan
                                .map((t) => TaskCard.fromMap(t))
                                .toList(),
                          ),

                        // Kategori Lainnya
                        if (folderLainnya.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              bottom: 12,
                              top: 8,
                            ),
                            child: Text(
                              'TUGAS LAINNYA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          ...folderLainnya.map((t) => TaskCard.fromMap(t)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- LAPISAN BLUR & FAB ---
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
                      _showAddTaskModal(); // <-- Memanggil form tugas saat diklik
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

// ==========================================
// KOMPONEN: FOLDER ACCORDION
// ==========================================
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
          initiallyExpanded: true, // Folder terbuka secara default
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

// ==========================================
// KOMPONEN: TASK CARD
// ==========================================
class TaskCard extends StatelessWidget {
  final String title;
  final String? instruction;
  final DateTime deadline;
  final String status;
  final bool isUrgent;

  const TaskCard({
    super.key,
    required this.title,
    this.instruction,
    required this.deadline,
    required this.status,
    required this.isUrgent,
  });

  // Fungsi pintar untuk mengubah Map (Data Base) menjadi Widget secara otomatis
  factory TaskCard.fromMap(Map<String, dynamic> data) {
    return TaskCard(
      title: data['title'],
      instruction: data['instruction'],
      deadline: data['deadline'],
      status: data['status'],
      isUrgent: data['isUrgent'],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = status == 'Done';

    // Logika warna cerdas berdasarkan waktu deadline
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    Color deadlineColor = const Color(0xFF86EFAC); // Hijau default (> 2 Hari)

    if (difference <= 1) {
      deadlineColor = const Color(0xFFFCA5A5); // Merah (< 1 Hari)
    } else if (difference <= 2) {
      deadlineColor = const Color(0xFFFDE047); // Kuning (1-2 Hari)
    }

    // Format tanggal menjadi teks yang mudah dibaca
    String deadlineText = DateFormat('dd MMM, HH:mm').format(deadline);

    return Container(
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
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
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
                  Container(
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
    );
  }
}
