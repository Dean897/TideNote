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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isFabOpen = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _folders = []; // Berubah mendukung parent (Nested)

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================
  // MANAJEMEN DATA & LOCAL STORAGE
  // ==========================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTasks = prefs.getString('tidenote_data');
    final String? savedFolders = prefs.getString('tidenote_folders');

    // Muat Folder (Migrasi otomatis jika data lama berupa String biasa)
    if (savedFolders != null) {
      final List<dynamic> decoded = json.decode(savedFolders);
      setState(() {
        if (decoded.isNotEmpty && decoded[0] is String) {
          _folders = decoded.map((e) => {'name': e, 'parent': null}).toList();
        } else {
          _folders = List<Map<String, dynamic>>.from(decoded);
        }
      });
    } else {
      setState(() {
        _folders = [
          {'name': 'Tugas Kuliah', 'parent': null},
          {'name': 'Semester 8', 'parent': 'Tugas Kuliah'}, // Contoh Nested
          {'name': 'Pekerjaan - UI/UX', 'parent': null},
        ];
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
            'folder': 'Semester 8',
          },
          {
            'id': '2',
            'title': 'Desain Wireframe',
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
    setState(() => _tasks.removeWhere((task) => task['id'] == id));
    _saveTasks();
  }

  void _toggleTaskStatus(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
      if (taskIndex != -1) {
        final currentStatus = _tasks[taskIndex]['status'];
        _tasks[taskIndex]['status'] = currentStatus == 'To-Do'
            ? 'In Progress'
            : (currentStatus == 'In Progress' ? 'Done' : 'To-Do');
      }
    });
    _saveTasks();
  }

  void _toggleTaskUrgency(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
      if (taskIndex != -1) {
        _tasks[taskIndex]['isUrgent'] =
            !(_tasks[taskIndex]['isUrgent'] ?? false);
      }
    });
    _saveTasks();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  // ==========================================
  // MODAL: NOTIFIKASI PINTAR (Sesuai Gambar 10)
  // ==========================================
  void _showNotificationModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFF8DBEE1),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sistem Notifikasi Pintar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TideNote mengingatkan Anda berdasarkan sisa waktu deadline secara otomatis:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildNotifLegend(
                  Colors.green.shade100,
                  Colors.green,
                  'Hijau (> 2 hari):',
                  '1x sehari (Pukul 19.00)',
                ),
                _buildNotifLegend(
                  Colors.yellow.shade100,
                  Colors.amber,
                  'Kuning (1-2 hari):',
                  '2x sehari (08.00 & 19.00)',
                ),
                _buildNotifLegend(
                  Colors.red.shade50,
                  Colors.red.shade400,
                  'Merah (< 24 jam):',
                  '3x sehari + 3 jam sblm deadline',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F7F0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotifLegend(
    Color bgColor,
    Color dotColor,
    String title,
    String desc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL: TAMBAH FOLDER NESTED (Sesuai Gambar 4)
  // ==========================================
  void _showAddFolderModal() {
    final TextEditingController folderController = TextEditingController();
    String? selectedParent;

    // Ambil folder yang bisa jadi parent (hindari rekursif tak terhingga)
    List<String> availableParents = _folders
        .where((f) => f['parent'] == null)
        .map((f) => f['name'] as String)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildFormContainer(
              ctx,
              'Tambah Folder',
              children: [
                _buildInputLabel('NAMA FOLDER'),
                TextField(
                  controller: folderController,
                  decoration: _inputDecoration('Misal: Semester 6'),
                ),
                const SizedBox(height: 16),
                _buildInputLabel('INDUK FOLDER (OPSIONAL)'),
                DropdownButtonFormField<String>(
                  value: selectedParent,
                  decoration: _inputDecoration('-- Jadikan Folder Utama --'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('-- Jadikan Folder Utama --'),
                    ),
                    ...availableParents.map(
                      (folder) => DropdownMenuItem<String>(
                        value: folder,
                        child: Text(folder),
                      ),
                    ),
                  ],
                  onChanged: (val) => setModalState(() => selectedParent = val),
                ),
                const SizedBox(height: 32),
                _buildSubmitButton('Buat Folder', () {
                  final folderName = folderController.text.trim();
                  if (folderName.isEmpty) return;
                  setState(() {
                    if (!_folders.any((f) => f['name'] == folderName)) {
                      _folders.add({
                        'name': folderName,
                        'parent': selectedParent,
                      });
                    }
                  });
                  _saveFolders();
                  Navigator.pop(ctx);
                }),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MODAL: TAMBAH TUGAS (Sesuai Gambar 2)
  // ==========================================
  void _showAddTaskModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController instructionController = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));
    String? selectedFolder = _folders.isNotEmpty
        ? _folders.first['name']
        : null;
    bool isUrgent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildFormContainer(
              ctx,
              'Tambah Tugas Baru',
              children: [
                _buildInputLabel('JUDUL TUGAS'),
                TextField(
                  controller: titleController,
                  decoration: _inputDecoration('Misal: Laporan Akhir'),
                ),
                const SizedBox(height: 16),

                _buildInputLabel('PILIH FOLDER'),
                DropdownButtonFormField<String>(
                  value: selectedFolder,
                  decoration: _inputDecoration('-- Tidak ada Folder (Umum) --'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('-- Tidak ada Folder (Umum) --'),
                    ),
                    ..._folders.map(
                      (f) => DropdownMenuItem<String>(
                        value: f['name'],
                        child: Text(f['name']),
                      ),
                    ),
                  ],
                  onChanged: (val) => setModalState(() => selectedFolder = val),
                ),
                const SizedBox(height: 16),

                _buildInputLabel('INSTRUKSI / CATATAN'),
                TextField(
                  controller: instructionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Tulis instruksi detail di sini...',
                  ),
                ),
                const SizedBox(height: 16),

                _buildInputLabel('DEADLINE WAKTU'),
                InkWell(
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedDeadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM/yyyy -- HH:mm',
                          ).format(selectedDeadline),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: isUrgent,
                      activeColor: Colors.orange.shade400,
                      onChanged: (val) =>
                          setModalState(() => isUrgent = val ?? false),
                    ),
                    const Text(
                      'Tandai sebagai Urgent (Api)',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSubmitButton('Simpan Tugas', () {
                  if (titleController.text.trim().isEmpty) return;
                  setState(() {
                    _tasks.add({
                      'id': DateTime.now().toString(),
                      'title': titleController.text,
                      'instruction': instructionController.text,
                      'deadline': selectedDeadline,
                      'status': 'To-Do',
                      'isUrgent': isUrgent,
                      'folder': selectedFolder ?? 'Lainnya',
                    });
                  });
                  _saveTasks();
                  Navigator.pop(ctx);
                }),
              ],
            );
          },
        );
      },
    );
  }

  // Komponen pembantu untuk UI Form Modal agar rapi
  Widget _buildFormContainer(
    BuildContext context,
    String title, {
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8DBEE1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RENDER POHON FOLDER & TUGAS (Nested Logika)
  // ==========================================
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

  List<Widget> _buildFolderTree() {
    // Ambil folder utama (yang tidak punya parent)
    final rootFolders = _folders
        .where((f) => f['parent'] == null)
        .map((f) => f['name'] as String)
        .toList();
    // Tambah kategori "Lainnya" untuk tugas tanpa folder
    if (!_folders.any((f) => f['name'] == 'Lainnya'))
      rootFolders.add('Lainnya');

    return rootFolders
        .map((rootName) => _buildAccordion(rootName, isSub: false))
        .toList();
  }

  Widget _buildAccordion(String folderName, {required bool isSub}) {
    final tasks = _getFilteredTasks(folderName);
    // Cari folder anak dari folder ini
    final subFolders = _folders
        .where((f) => f['parent'] == folderName)
        .map((f) => f['name'] as String)
        .toList();

    if (tasks.isEmpty && subFolders.isEmpty && _searchQuery.isNotEmpty)
      return const SizedBox.shrink();

    // Map List Tugas menjadi TaskCard
    List<Widget> taskWidgets = tasks
        .map(
          (t) => TaskCard.fromMap(
            t,
            onDelete: () => _deleteTask(t['id']),
            onToggleStatus: () => _toggleTaskStatus(t['id']),
            onToggleUrgency: () => _toggleTaskUrgency(t['id']),
          ),
        )
        .toList();

    // Map List Folder Anak
    List<Widget> subFolderWidgets = subFolders
        .map((subName) => _buildAccordion(subName, isSub: true))
        .toList();

    return FolderAccordion(
      folderName: folderName,
      isSubFolder: isSub,
      taskCount: tasks.length,
      children: [...subFolderWidgets, ...taskWidgets],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                      InkWell(
                        onTap: _showNotificationModal, // Klik Notifikasi
                        child: Container(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
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

                  // Tabs
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

                  // Content Area
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: _buildFolderTree(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blur Latar FAB
          if (_isFabOpen)
            GestureDetector(
              onTap: _toggleFab,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(color: Colors.white.withOpacity(0.4)),
              ),
            ),

          // FAB dengan Animasi Slide & Fade
          Positioned(
            bottom: 32,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: _isFabOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedSlide(
                    offset: _isFabOpen ? Offset.zero : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 200),
                    child: _isFabOpen
                        ? _buildFabOption(
                            icon: Icons.create_new_folder_rounded,
                            label: 'Tambah Folder',
                            onTap: () {
                              _toggleFab();
                              _showAddFolderModal();
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _isFabOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: AnimatedSlide(
                    offset: _isFabOpen ? Offset.zero : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 250),
                    child: _isFabOpen
                        ? _buildFabOption(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Tambah Tugas',
                            onTap: () {
                              _toggleFab();
                              _showAddTaskModal();
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
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

  // Desain tombol FAB yang baru sesuai Gambar 6
  Widget _buildFabOption({
    required IconData icon,
    required String label,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF8DBEE1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KOMPONEN: FOLDER ACCORDION (Mendukung Nested)
// ==========================================
class FolderAccordion extends StatelessWidget {
  final String folderName;
  final int taskCount;
  final List<Widget> children;
  final bool isSubFolder;

  const FolderAccordion({
    super.key,
    required this.folderName,
    required this.taskCount,
    required this.children,
    this.isSubFolder = false,
  });

  @override
  Widget build(BuildContext context) {
    // Jika folder kosong, jangan tampilkan apa-apa
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Efek visual jika ini adalah sub-folder (menjorok ke dalam dengan garis kiri)
      padding: isSubFolder ? const EdgeInsets.only(left: 16) : EdgeInsets.zero,
      decoration: isSubFolder
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFDFF6FF), width: 2),
              ),
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSubFolder ? 13 : 14,
                color: const Color(0xFF334155),
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
            children: children,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// KOMPONEN: TASK CARD (Dengan Ikon Api Interaktif)
// ==========================================
class TaskCard extends StatelessWidget {
  final String id, title, status;
  final String? instruction;
  final DateTime deadline;
  final bool isUrgent;
  final VoidCallback onDelete, onToggleStatus, onToggleUrgency;

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
    required this.onToggleUrgency,
  });

  factory TaskCard.fromMap(
    Map<String, dynamic> data, {
    required VoidCallback onDelete,
    required VoidCallback onToggleStatus,
    required VoidCallback onToggleUrgency,
  }) {
    return TaskCard(
      id: data['id'],
      title: data['title'],
      instruction: data['instruction'],
      deadline: data['deadline'],
      status: data['status'],
      isUrgent: data['isUrgent'] ?? false,
      onDelete: onDelete,
      onToggleStatus: onToggleStatus,
      onToggleUrgency: onToggleUrgency,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = status == 'Done';
    final difference = deadline.difference(DateTime.now()).inDays;
    Color deadlineColor = difference <= 1
        ? const Color(0xFFFCA5A5)
        : difference <= 2
        ? const Color(0xFFFDE047)
        : const Color(0xFF86EFAC);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (d) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
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
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (instruction != null && instruction!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    instruction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
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
                          DateFormat('dd MMM, HH:mm').format(deadline),
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
            // Ikon Api Interaktif (Bisa diklik)
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: Icon(
                  isUrgent
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: isDone
                      ? Colors.transparent
                      : (isUrgent
                            ? Colors.orange.shade400
                            : Colors.grey.shade300),
                  size: 24,
                ),
                onPressed: isDone
                    ? null
                    : onToggleUrgency, // Klik untuk menyalakan/mematikan
              ),
            ),
          ],
        ),
      ),
    );
  }
}
