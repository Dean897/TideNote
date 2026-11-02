import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tidenote_data');
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((item) {
      final task = item as Map<String, dynamic>;
      return <String, dynamic>{
        'id': task['id'],
        'title': task['title'],
        'instruction': task['instruction'],
        'deadline': DateTime.parse(task['deadline'] as String),
        'status': task['status'],
        'isUrgent': task['isUrgent'],
        'folder': task['folder'],
        'proofImage': task['proofImage'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tidenote_folders');
    if (raw == null) {
      final defaults = [
        {'name': 'Tugas Kuliah', 'parent': null},
        {'name': 'Semester 8', 'parent': 'Tugas Kuliah'},
        {'name': 'Pekerjaan - UI/UX', 'parent': null},
      ];
      await saveFolders(defaults);
      return defaults;
    }
    final decoded = json.decode(raw) as List<dynamic>;
    if (decoded.isNotEmpty && decoded.first is String) {
      return decoded.map((name) => {'name': name, 'parent': null}).toList();
    }
    return decoded
        .map((folder) => Map<String, dynamic>.from(folder as Map))
        .toList();
  }

  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final data = tasks
        .map(
          (task) => {
            'id': task['id'],
            'title': task['title'],
            'instruction': task['instruction'],
            'deadline': (task['deadline'] as DateTime).toIso8601String(),
            'status': task['status'],
            'isUrgent': task['isUrgent'],
            'folder': task['folder'],
            'proofImage': task['proofImage'],
          },
        )
        .toList();
    await prefs.setString('tidenote_data', json.encode(data));
  }

  Future<void> saveFolders(List<Map<String, dynamic>> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tidenote_folders', json.encode(folders));
  }
}
