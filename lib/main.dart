import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

// MODUL NOTIFIKASI & WAKTU
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Inisialisasi Mesin Notifikasi Global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Set zona waktu agar alarm akurat (WIB)
  if (!kIsWeb) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

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
  void _requestNotificationPermission() {
    if (!kIsWeb) {
      try {
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestExactAlarmsPermission();
      } catch (_) {
        // Tidak semua environment mendukung platform notifications, termasuk test.
      }
    }
  }

  Future<void> scheduleTaskNotification(
    String id,
    String title,
    DateTime deadline,
  ) async {
    if (kIsWeb) return;

    await cancelTaskNotification(id);

    const androidDetails = AndroidNotificationDetails(
      'tidenote_channel',
      'TideNote Smart Reminders',
      channelDescription: 'Pengingat Notifikasi Pintar TideNote',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF8DBEE1),
      icon: '@mipmap/ic_launcher',
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    final difference = deadline.difference(now);

    // 1. KATEGORI HIJAU (> 2 hari / > 48 jam) -> 1x Sehari (19.00 WIB)
    if (difference.inHours > 48) {
      var scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
      if (scheduledDate.isBefore(now))
        scheduledDate = scheduledDate.add(const Duration(days: 1));

      if (scheduledDate.isBefore(deadline)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id.hashCode,
          title: '🟢 TideNote: Status Aman',
          body: 'Tugas "$title" masih memiliki waktu lebih dari 2 hari.',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
    // 2. KATEGORI KUNING (1 - 2 hari / 24-48 jam) -> 2x Sehari (08.00 & 19.00 WIB)
    else if (difference.inHours >= 24 && difference.inHours <= 48) {
      var morningTime = DateTime(now.year, now.month, now.day, 8, 0);
      if (morningTime.isBefore(now))
        morningTime = morningTime.add(const Duration(days: 1));

      if (morningTime.isBefore(deadline)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id.hashCode + 1,
          title: '🟡 TideNote Pengingat Pagi',
          body:
              'Tugas "$title" dikumpulkan besok! Tetap semangat menyelesaikannya.',
          scheduledDate: tz.TZDateTime.from(morningTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      var eveningTime = DateTime(now.year, now.month, now.day, 19, 0);
      if (eveningTime.isBefore(now))
        eveningTime = eveningTime.add(const Duration(days: 1));

      if (eveningTime.isBefore(deadline)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id.hashCode + 2,
          title: '🟡 TideNote Pengingat Malam',
          body: 'Jangan lupa cicil tugas "$title" sebelum besok.',
          scheduledDate: tz.TZDateTime.from(eveningTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
    // 3. KATEGORI MERAH (< 24 jam) -> 3x Sehari + 3 Jam Sblm Deadline
    else if (difference.inHours < 24 && difference.inHours > 0) {
      final emergencyTime = deadline.subtract(const Duration(hours: 3));
      if (emergencyTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id.hashCode + 3,
          title: '🔴 PERINGATAN DARURAT!',
          body: 'Waktu tersisa kurang dari 3 jam untuk tugas "$title"!',
          scheduledDate: tz.TZDateTime.from(emergencyTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      var noonTime = DateTime(now.year, now.month, now.day, 13, 0);
      if (noonTime.isAfter(now) && noonTime.isBefore(deadline)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id.hashCode + 4,
          title: '🔴 TideNote: Mendekati Deadline',
          body: 'Tugas "$title" harus dikumpulkan hari ini!',
          scheduledDate: tz.TZDateTime.from(noonTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> cancelTaskNotification(String id) async {
    if (kIsWeb) return;
    // Diperbarui: menggunakan int id langsung, bukan named parameter.
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode);
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode + 1);
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode + 2);
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode + 3);
    await flutterLocalNotificationsPlugin.cancel(id: id.hashCode + 4);
  }

  // ==========================================
  // MANAJEMEN DATA & LOCAL STORAGE
  // ==========================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTasks = prefs.getString('tidenote_data');
    final String? savedFolders = prefs.getString('tidenote_folders');

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
          {'name': 'Semester 8', 'parent': 'Tugas Kuliah'},
          {'name': 'Pekerjaan - UI/UX', 'parent': null},
        ];
      });
      _saveFolders();
    }

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
            'proofImage': item['proofImage'],
          };
        }).toList();
      });
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
        'proofImage': task['proofImage'],
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
    cancelTaskNotification(id);
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
                  cancelTaskNotification(t['id']);
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
      scheduleTaskNotification(
        _tasks[taskIndex]['id'],
        _tasks[taskIndex]['title'],
        _tasks[taskIndex]['deadline'],
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
        cancelTaskNotification(_tasks[taskIndex]['id']);
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

                  scheduleTaskNotification(
                    newId,
                    titleController.text,
                    selectedDeadline,
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
                        child: const Icon(
                          Icons.notifications_active_rounded,
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
}

class FolderAccordion extends StatelessWidget {
  final String folderName;
  final int taskCount;
  final List<Widget> children;
  final bool isSubFolder;
  final VoidCallback? onDelete;
  const FolderAccordion({
    super.key,
    required this.folderName,
    required this.taskCount,
    required this.children,
    this.isSubFolder = false,
    this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: isSubFolder ? const EdgeInsets.only(left: 16) : EdgeInsets.zero,
      decoration: isSubFolder
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFDFF6FF), width: 2),
              ),
            )
          : null,
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                if (onDelete != null && folderName != 'Lainnya') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8,
            ),
            children: children.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Belum ada tugas di folder ini',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                : children,
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String id, title, status;
  final String? instruction, proofImage;
  final DateTime deadline;
  final bool isUrgent;
  final VoidCallback onDelete, onToggleStatus, onToggleUrgency;
  const TaskCard({
    super.key,
    required this.id,
    required this.title,
    this.instruction,
    this.proofImage,
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
      proofImage: data['proofImage'],
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
    bool isOverdue = deadline.isBefore(DateTime.now()) && !isDone;
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
          color: isDone
              ? const Color(0xFFF0FDF4)
              : (isOverdue ? const Color(0xFFFEF2F2) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? const Color(0xFF86EFAC)
                : (isOverdue ? const Color(0xFFFCA5A5) : deadlineColor),
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
                      color: isDone
                          ? const Color(0xFF166534)
                          : (isOverdue
                                ? Colors.red.shade900
                                : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (instruction != null && instruction!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    instruction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone
                          ? const Color(0xFF15803D)
                          : (isOverdue
                                ? Colors.red.shade700
                                : Colors.grey.shade500),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : (isOverdue
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFF1F5F9)),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 12),
                if (isDone && proofImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(proofImage!),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDone
                              ? const Color(0xFF22C55E)
                              : (isOverdue
                                    ? Colors.red.shade400
                                    : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(deadline),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF166534)
                                : (isOverdue
                                      ? Colors.red.shade700
                                      : Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: isOverdue ? null : onToggleStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFDCFCE7)
                              : (isOverdue
                                    ? Colors.red.shade100
                                    : (status == 'In Progress'
                                          ? const Color(0xFFBFF4FF)
                                          : Colors.grey.shade100)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOverdue ? 'Terlambat' : status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? const Color(0xFF15803D)
                                : (isOverdue
                                      ? Colors.red.shade700
                                      : (status == 'In Progress'
                                            ? const Color(0xFF5AB2D3)
                                            : Colors.grey.shade600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: Icon(
                  isUrgent
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: isDone
                      ? const Color(0xFF86EFAC)
                      : (isOverdue
                            ? Colors.red.shade300
                            : (isUrgent
                                  ? Colors.orange.shade400
                                  : Colors.grey.shade300)),
                  size: 24,
                ),
                onPressed: isDone || isOverdue ? null : onToggleUrgency,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
