import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'my_reels.dart';

void main() {
  runApp(const ReelMakerApp());
}

class ReelMakerApp extends StatelessWidget {
  const ReelMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Material You Dynamic Color integration
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme colorScheme;
        if (darkDynamic != null) {
          colorScheme = darkDynamic.harmonized();
        } else {
          colorScheme = ColorScheme.fromSeed(
            seedColor: Colors.cyanAccent,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MRB Cutter Pro',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            fontFamily: 'Roboto',
          ),
          home: const SplashIntroScreen(),
        );
      },
    );
  }
}

// ==========================================
// 1. BRANDED SPLASH SCREEN
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
              Image.asset(
                'assets/logo.png',
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.movie_creation_outlined, size: 100, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. PROFESSIONAL DASHBOARD
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;
  String _statusText = "Ready to generate viral content";
  String _logText = "Engine Idle. Awaiting user input...";
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
        _statusText = "Brand Logo Linked Successfully";
      });
    }
  }

  Future<void> processMovie() async {
    try {
      setState(() {
        _statusText = "Authenticating Access...";
        _logText = "Verifying storage permissions...";
      });

      await _requestPermissions();

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
      
      if (result == null) {
        setState(() {
          _statusText = "Operation Aborted";
          _logText = "No video source selected.";
        });
        return;
      }

      setState(() {
        _isProcessing = true;
        _statusText = "Optimizing Video Assets... ⚡";
        _logText = "Initializing high-speed FFmpeg engine...";
      });

      String inputPath = result.files.single.path!;
      String movieName = result.files.single.name.split('.').first;
      String outputDirPath = '/storage/emulated/0/Download/MRB_Cutter_$movieName';
      
      Directory outputDir = Directory(outputDirPath);
      if (!await outputDir.exists()) await outputDir.create(recursive: true);

      String outputPathPattern = '$outputDirPath/reel_%03d.mp4';
      
      // OPTIMIZED COMMAND: Fast preset, Start Index 1, Multi-threading enabled
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
            _statusText = "Process Complete! 📂";
            _logText = "Files exported to Downloads folder. Starting index: 1";
          } else {
            _statusText = "Processing Failed";
            _logText = "FFmpeg Exception Code: $returnCode";
          }
        });
      }, (log) {
        setState(() { _logText = log.getMessage(); });
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = "System Error Occurred";
        _logText = e.toString();
      });
    }
  }

  void showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text("This module is currently in beta. Stay tuned for the next release!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Understood")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRB DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => showComingSoonDialog("Creator Profile"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Professional Welcome Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text("Welcome, Creator. Select a movie to generate high-quality 9:16 reels.", 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Expressive Status Icon
            Center(
              child: Icon(
                _isProcessing ? Icons.sync_rounded : Icons.auto_awesome_rounded, 
                size: 100, 
                color: _watermarkPath != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Console Terminal Log
            Container(
              padding: const EdgeInsets.all(12),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
              ),
              child: SingleChildScrollView(
                child: Text("> $_logText", 
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontFamily: 'monospace')),
              ),
            ),
            const Spacer(),

            if (_isProcessing) 
              const Center(child: Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator()))
            else ...[
              // Library & Settings Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReelsScreen()));
                      },
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text("My Library"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showComingSoonDialog("App Configurations"),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text("Settings"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Functional Buttons
              OutlinedButton.icon(
                onPressed: pickWatermark,
                icon: const Icon(Icons.branding_watermark_outlined),
                label: const Text("Attach Brand Watermark"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
              ),
              const SizedBox(height: 16),
              
              FilledButton.icon(
                onPressed: processMovie,
                icon: const Icon(Icons.movie_filter_outlined, size: 28),
                label: const Text("Process & Generate Reels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}