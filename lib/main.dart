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
      debugShowCheckedModeBanner:
          false, // Menghilangkan pita merah 'DEBUG' di pojok kanan
      theme: ThemeData(
        // Menggunakan warna background off-white dari prototipemu
        scaffoldBackgroundColor: const Color(0xFFF6F7F0),
        // Warna utama biru pastel
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
    // Scaffold adalah kanvas utama untuk satu halaman
    return Scaffold(
      // SafeArea memastikan UI tidak tertutup poni (notch) HP
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TideNote.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8DBEE1), // Warna teks gradasi sementara
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Menyiapkan...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
