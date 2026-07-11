import 'package:flutter/material.dart';

void main() {
  runApp(const TideNoteApp());
}

class TideNoteApp extends StatelessWidget {
  const TideNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TideNote',
      debugShowCheckedModeBanner: false, // Menghilangkan pita merah 'DEBUG'
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFFF6F7F0,
        ), // Background off-white
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ---
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
                  // Tombol Notifikasi (Squircle)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8DBEE1).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF8DBEE1),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- 2. SEARCH BAR ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8DBEE1).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari tugas atau instruksi...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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

              const SizedBox(height: 28),

              // --- 3. MENU TABS ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF8DBEE1), width: 2),
                      ),
                    ),
                    child: const Text(
                      'Tugas Aktif',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8DBEE1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Arsip Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- 4. DAFTAR TUGAS (ListView) ---
              // Expanded wajib berada di dalam Column agar mengisi sisa layar ke bawah
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    // Simulasi Tugas 1: Status Merah & Urgent
                    TaskCard(
                      title: 'Revisi Proposal Skripsi',
                      instruction:
                          'Perbaiki bab 2 sesuai arahan dosen pembimbing.',
                      deadlineText: 'Hari ini, 23:59',
                      status: 'To-Do',
                      isUrgent: true,
                      deadlineColor: Color(0xFFFCA5A5), // Merah
                    ),

                    // Simulasi Tugas 2: Status Kuning
                    TaskCard(
                      title: 'Desain Wireframe TideNote',
                      instruction:
                          'Gunakan bentuk squircle dan warna pastel blue.',
                      deadlineText: 'Besok, 12:00',
                      status: 'In Progress',
                      isUrgent: false,
                      deadlineColor: Color(0xFFFDE047), // Kuning
                    ),

                    // Simulasi Tugas 3: Status Hijau
                    TaskCard(
                      title: 'Belanja Bulanan',
                      instruction: 'Beli sabun, sampo, dan bahan makanan.',
                      deadlineText: '14 Jul, 09:00',
                      status: 'To-Do',
                      isUrgent: false,
                      deadlineColor: Color(0xFF86EFAC), // Hijau
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- KOMPONEN TASK CARD ---
class TaskCard extends StatelessWidget {
  final String title;
  final String? instruction;
  final String deadlineText;
  final String status;
  final bool isUrgent;
  final Color deadlineColor;

  const TaskCard({
    super.key,
    required this.title,
    this.instruction,
    required this.deadlineText,
    required this.status,
    required this.isUrgent,
    required this.deadlineColor,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = status == 'Done';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20), // Bentuk Squircle
        border: Border.all(
          color: isDone ? Colors.transparent : deadlineColor,
          width: 2,
        ),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: deadlineColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Tugas
              Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDone
                        ? Colors.grey.shade400
                        : Colors.blueGrey.shade800,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Instruksi
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

              // Footer Card (Waktu & Status)
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
                  // Status Pill
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
                    child: Row(
                      children: [
                        Text(
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
                        if (!isDone) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: status == 'In Progress'
                                ? const Color(0xFF5AB2D3)
                                : Colors.grey.shade600,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Ikon Urgent
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
