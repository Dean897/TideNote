import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/proof_image_saver.dart';
import '../widgets/folder_accordion.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isFabOpen = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _folders = [];

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _requestNotificationPermission();
  }

  // ==========================================
  // LOGIKA NOTIFIKASI PINTAR (HIJAU, KUNING, MERAH)
  // (DIPERBARUI SESUAI VERSI TERBARU FLUTTER_LOCAL_NOTIFICATIONS)
  // ==========================================
  Future<void> _requestNotificationPermission() async {
    await NotificationService.instance.requestPermissions();
  }

  Future<void> _refreshPendingNotifications() async {
    for (final task in _tasks) {
      if (task['status'] != 'Done') {
        await NotificationService.instance.scheduleTaskNotification(
          task['id'],
          task['title'],
          task['deadline'],
          instruction: task['instruction']?.toString(),
        );
      }
    }
  }

  Future<void> _showNotificationGuide() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCFEFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      size: 64,
                      color: Color(0xFF8DBEE1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sistem Notifikasi Pintar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TideNote mengingatkan Anda berdasarkan sisa waktu deadline secara otomatis:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildNotificationGuideCard(
                    color: const Color(0xFF7AD97C),
                    tint: const Color(0xFFEAFBE7),
                    title: 'Hijau (> 2 hari)',
                    description: '1x sehari (Pukul 19.00)',
                  ),
                  const SizedBox(height: 14),
                  _buildNotificationGuideCard(
                    color: const Color(0xFFF4C542),
                    tint: const Color(0xFFFFF7D8),
                    title: 'Kuning (1-2 hari)',
                    description: '2x sehari (08.00 & 19.00)',
                  ),
                  const SizedBox(height: 14),
                  _buildNotificationGuideCard(
                    color: const Color(0xFFE97777),
                    tint: const Color(0xFFFFF0F0),
                    title: 'Merah (< 24 jam)',
                    description: '3x sehari + 3 jam sebelum deadline',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8DBEE1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _showTestNotification();
                      },
                      child: const Text(
                        'Kirim Notifikasi Tes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationGuideCard({
    required Color color,
    required Color tint,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: Color(0xFF475569),
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTestNotification() async {
    await NotificationService.instance.showTestNotification();
  }

  // ==========================================
  // MANAJEMEN DATA & LOCAL STORAGE
  // ==========================================
  Future<void> _loadData() async {
    final storage = StorageService.instance;
    final loadedFolders = await storage.loadFolders();
    final loadedTasks = await storage.loadTasks();

    if (!mounted) return;
    setState(() {
      _folders = loadedFolders;
      _tasks = loadedTasks;
    });
    await _refreshPendingNotifications();
  }

  Future<void> _saveTasks() => StorageService.instance.saveTasks(_tasks);

  Future<void> _saveFolders() => StorageService.instance.saveFolders(_folders);

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((task) => task['id'] == id));
    NotificationService.instance.cancelTaskNotification(id);
    _saveTasks();
  }

  void _deleteFolder(String folderName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Hapus Folder?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus folder "$folderName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                _folders.removeWhere(
                  (f) => f['name'] == folderName || f['parent'] == folderName,
                );
                final tasksToDelete = _tasks
                    .where((t) => t['folder'] == folderName)
                    .toList();
                for (var t in tasksToDelete) {
                  NotificationService.instance.cancelTaskNotification(t['id']);
                }
                _tasks.removeWhere((t) => t['folder'] == folderName);
              });
              _saveFolders();
              _saveTasks();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOGIKA STATUS & BUKTI FOTO
  // ==========================================
  void _toggleTaskStatus(String id) {
    final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
    if (taskIndex == -1) return;

    final currentStatus = _tasks[taskIndex]['status'];

    if (currentStatus == 'To-Do' || currentStatus == 'In Progress') {
      _showProofPickerModal(taskIndex);
    } else {
      setState(() {
        _tasks[taskIndex]['status'] = 'To-Do';
        _tasks[taskIndex].remove('proofImage');
      });
      NotificationService.instance.scheduleTaskNotification(
        _tasks[taskIndex]['id'],
        _tasks[taskIndex]['title'],
        _tasks[taskIndex]['deadline'],
        instruction: _tasks[taskIndex]['instruction']?.toString(),
      );
      _saveTasks();
    }
  }

  void _showProofPickerModal(int taskIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Bukti Tugas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wajib menyertakan foto agar status menjadi Selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF8DBEE1),
                ),
              ),
              title: const Text(
                'Ambil dari Kamera',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(taskIndex, ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF8DBEE1),
                ),
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(taskIndex, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(int taskIndex, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 30,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          _tasks[taskIndex]['status'] = 'Done';
          _tasks[taskIndex]['proofImage'] = base64Image;
        });
        NotificationService.instance.cancelTaskNotification(
          _tasks[taskIndex]['id'],
        );
        _saveTasks();
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  void _toggleTaskUrgency(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == id);
      if (taskIndex != -1)
        _tasks[taskIndex]['isUrgent'] =
            !(_tasks[taskIndex]['isUrgent'] ?? false);
    });
    _saveTasks();
  }

  void _toggleFab() => setState(() => _isFabOpen = !_isFabOpen);

  // ==========================================
  // MODAL FORMS
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
                      if (time != null)
                        setModalState(
                          () => selectedDeadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
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

                  final newId = DateTime.now().toString();
                  setState(() {
                    _tasks.add({
                      'id': newId,
                      'title': titleController.text,
                      'instruction': instructionController.text,
                      'deadline': selectedDeadline,
                      'status': 'To-Do',
                      'isUrgent': isUrgent,
                      'folder': selectedFolder ?? 'Lainnya',
                    });
                  });

                  NotificationService.instance.scheduleTaskNotification(
                    newId,
                    titleController.text,
                    selectedDeadline,
                    instruction: instructionController.text,
                  );

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

  void _showAddFolderModal() {
    final TextEditingController folderController = TextEditingController();
    String? selectedParent;
    List<String> availableParents = _folders
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
                  decoration: _inputDecoration('Misal: Modul 1'),
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
                    if (!_folders.any((f) => f['name'] == folderName))
                      _folders.add({
                        'name': folderName,
                        'parent': selectedParent,
                      });
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
      bool isOverdue =
          task['deadline'].isBefore(DateTime.now()) && task['status'] != 'Done';
      bool matchesTab = false;
      if (_selectedTabIndex == 0) {
        matchesTab = !isOverdue && task['status'] != 'Done';
      } else if (_selectedTabIndex == 1) {
        matchesTab = task['status'] == 'Done';
      } else if (_selectedTabIndex == 2) {
        matchesTab = isOverdue;
      }
      return matchesFolder && matchesSearch && matchesTab;
    }).toList();
  }

  List<Widget> _buildFolderTree() {
    final rootFolders = _folders
        .where((f) => f['parent'] == null)
        .map((f) => f['name'] as String)
        .toList();
    if (!_folders.any((f) => f['name'] == 'Lainnya'))
      rootFolders.add('Lainnya');
    return rootFolders
        .map((rootName) => _buildAccordion(rootName, isSub: false))
        .toList();
  }

  Widget _buildAccordion(String folderName, {required bool isSub}) {
    final tasks = _getFilteredTasks(folderName);
    final subFolders = _folders
        .where((f) => f['parent'] == folderName)
        .map((f) => f['name'] as String)
        .toList();
    if (_selectedTabIndex != 0 && tasks.isEmpty && subFolders.isEmpty)
      return const SizedBox.shrink();
    if (tasks.isEmpty && subFolders.isEmpty && _searchQuery.isNotEmpty)
      return const SizedBox.shrink();
    List<Widget> taskWidgets = tasks
        .map(
          (t) => TaskCard.fromMap(
            t,
            onDelete: () => _deleteTask(t['id']),
            onToggleStatus: () => _toggleTaskStatus(t['id']),
            onToggleUrgency: () => _toggleTaskUrgency(t['id']),
            onViewProofImage: t['proofImage'] != null
                ? () => _showProofImagePreview(
                    t['proofImage'].toString(),
                    t['title'].toString(),
                  )
                : null,
          ),
        )
        .toList();
    List<Widget> subFolderWidgets = subFolders
        .map((subName) => _buildAccordion(subName, isSub: true))
        .toList();
    return FolderAccordion(
      folderName: folderName,
      isSubFolder: isSub,
      taskCount: tasks.length,
      onDelete: () => _deleteFolder(folderName),
      children: [...subFolderWidgets, ...taskWidgets],
    );
  }

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTabIndex == index;
    Color tabColor = index == 2 ? Colors.red.shade400 : const Color(0xFF8DBEE1);
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? tabColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? tabColor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF8DBEE1).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF8DBEE1).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
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
                              color: Colors.grey.shade600,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showNotificationGuide,
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF8DBEE1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildTab(0, 'Tugas Aktif'),
                        const SizedBox(width: 20),
                        _buildTab(1, 'Arsip Selesai'),
                        const SizedBox(width: 20),
                        _buildTab(2, 'Tugas Terlambat'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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

  Widget _buildInputLabel(String text) => Padding(
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
  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
  Widget _buildSubmitButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8DBEE1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
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
  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
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

  Future<void> _showProofImagePreview(String proofImage, String title) async {
    if (!mounted) return;

    final imageBytes = base64Decode(proofImage);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Container(
                          color: Colors.black,
                          width: double.infinity,
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  'Gambar tidak dapat ditampilkan',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8DBEE1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final savedLocation = await saveProofImage(
                          imageBytes,
                          fileName:
                              'bukti-${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}.png',
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bukti disimpan ke $savedLocation'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Unduh Gambar'),
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
}
