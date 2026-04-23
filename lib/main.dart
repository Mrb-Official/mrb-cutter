import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'my_reels.dart';

void main() {
  runApp(const ReelMakerApp());
}

class ReelMakerApp extends StatelessWidget {
  const ReelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MRB Cutter Pro',
      // YAHAN MATERIAL 3 DARK THEME SET KI HAI
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent, // Google style dynamic colors isse banenge
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashIntroScreen(),
    );
  }
}

// ==========================================
// 1. TERA CUSTOM LOGO WALA SPLASH SCREEN
// ==========================================
class SplashIntroScreen extends StatefulWidget {
  const SplashIntroScreen({super.key});

  @override
  State<SplashIntroScreen> createState() => _SplashIntroScreenState();
}

class _SplashIntroScreenState extends State<SplashIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 3 second baad apne aap Home Screen par jayega
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TERA LOGO YAHAN DIKHEGA
              Image.asset(
                'assets/logo.png', 
                width: 180, 
                height: 180,
                // Agar galti se image nahi mili toh app crash nahi hogi
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, size: 120),
              ),
              const SizedBox(height: 30),
              // Material 3 style loading indicator
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. MAIN HOME SCREEN
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;
  String _statusText = "Ready for the next viral hit!";
  String _logText = "System Idle. Awaiting commands...";
  String? _watermarkPath;

  Future<void> _requestPermissions() async {
    await Permission.videos.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> pickWatermark() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _watermarkPath = result.files.single.path;
        _statusText = "Premium Logo Attached! 👑";
      });
    }
  }

  Future<void> processMovie() async {
    try {
      setState(() {
        _statusText = "Checking Permissions...";
        _logText = "Requesting storage access...";
      });

      await _requestPermissions();

      setState(() {
        _statusText = "Opening Gallery...";
        _logText = "Waiting for video selection...";
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
      
      if (result == null) {
        setState(() {
          _statusText = "Action Cancelled!";
          _logText = "No video selected.";
        });
        return;
      }

      setState(() {
        _isProcessing = true;
        _statusText = "Extracting Raw Power... ⚡";
        _logText = "Starting FFmpeg Engine in Fast Mode...";
      });

      String inputPath = result.files.single.path!;
      String movieName = result.files.single.name.split('.').first;
      String outputDirPath = '/storage/emulated/0/Download/MRB_Reels_$movieName';
      
      Directory outputDir = Directory(outputDirPath);
      if (!await outputDir.exists()) await outputDir.create(recursive: true);

      String outputPathPattern = '$outputDirPath/reel_%03d.mp4';
      
      // FAST PROCESSING + INDEX START FROM 1 (-segment_start_number 1)
      String ffmpegCommand;
      if (_watermarkPath != null) {
        ffmpegCommand = '-i "$inputPath" -i "$_watermarkPath" -filter_complex "[0:v]crop=ih*(9/16):ih[v];[v][1:v]overlay=main_w-overlay_w-20:20" -c:v libx264 -preset ultrafast -crf 28 -threads 0 -c:a aac -f segment -segment_time 30 -segment_start_number 1 -reset_timestamps 1 "$outputPathPattern"';
      } else {
        ffmpegCommand = '-i "$inputPath" -vf "crop=ih*(9/16):ih" -c:v libx264 -preset ultrafast -crf 28 -threads 0 -c:a aac -f segment -segment_time 30 -segment_start_number 1 -reset_timestamps 1 "$outputPathPattern"';
      }

      await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
        final returnCode = await session.getReturnCode();
        setState(() {
          _isProcessing = false;
          if (ReturnCode.isSuccess(returnCode)) {
            _statusText = "Success! Reels in Downloads 📂";
            _logText = "All clips saved! Index started from 1.";
          } else {
            _statusText = "Process Failed! ❌";
            _logText = "FFmpeg Error Code: $returnCode";
          }
        });
      }, (log) {
        setState(() { _logText = log.getMessage(); });
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = "Error Occurred! ⚠️";
        _logText = e.toString();
      });
    }
  }

  void showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text("Bhai, yeh feature next update me aayega! 🚀"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRB DASHBOARD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin),
            onPressed: () => showComingSoonDialog("Creator Profile"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Material 3 Card Style
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.waving_hand_rounded, color: Colors.amberAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Welcome back, Creator! Let's generate some viral content today.", 
                        style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: Icon(Icons.auto_awesome_motion_rounded, 
                size: 90, color: _watermarkPath != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 15),
            Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
              ),
              child: SingleChildScrollView(child: Text("> $_logText", style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontFamily: 'monospace'))),
            ),
            const Spacer(),

            if (_isProcessing) 
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyReelsScreen()),
                        );
                      },
                      icon: const Icon(Icons.folder_special, size: 18),
                      label: const Text("My Reels"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showComingSoonDialog("App Settings"),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text("Settings"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: pickWatermark,
                icon: const Icon(Icons.branding_watermark),
                label: const Text("1. Select Premium Logo"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 15),
              
              FilledButton.icon(
                onPressed: processMovie,
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: const Text("2. SELECT VIDEO & CUT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}