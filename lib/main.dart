import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min/return_code.dart';
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
          title: 'mrb cutter', 
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            fontFamily: 'Roboto',
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ==========================================
// 1. SPLASH SCREEN
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
                'assets/logo.jpg',
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.movie_filter_rounded, size: 120, color: Theme.of(context).colorScheme.primary),
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
// 2. MAIN HOME SCREEN
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
        _statusText = "Extracting Raw Power...";
        _logText = "Starting FFmpeg HQ Engine...";
      });

      String inputPath = result.files.single.path!;
      String movieName = result.files.single.name.split('.').first;
      
      // Yahan maine fix kiya hai taaki My Library (my_reels.dart) scan kar sake
      String outputDirPath = '/storage/emulated/0/Download/MRB_$movieName';
      
      Directory outputDir = Directory(outputDirPath);
      if (!await outputDir.exists()) await outputDir.create(recursive: true);

      String outputPathPattern = '$outputDirPath/reel_%03d.mp4';
      
      String ffmpegCommand;
      if (_watermarkPath != null) {
        ffmpegCommand = '-i "$inputPath" -i "$_watermarkPath" -filter_complex "[0:v]crop=ih*(9/16):ih[v];[v][1:v]overlay=main_w-overlay_w-20:20" -c:v libx264 -preset ultrafast -crf 18 -threads 0 -c:a copy -f segment -segment_time 30 -segment_start_number 1 -reset_timestamps 1 "$outputPathPattern"';
      } else {
        ffmpegCommand = '-i "$inputPath" -vf "crop=ih*(9/16):ih" -c:v libx264 -preset ultrafast -crf 18 -threads 0 -c:a copy -f segment -segment_time 30 -segment_start_number 1 -reset_timestamps 1 "$outputPathPattern"';
      }

      await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
        final returnCode = await session.getReturnCode();
        setState(() {
          _isProcessing = false;
          if (ReturnCode.isSuccess(returnCode)) {
            _statusText = "Success! Reels in Downloads 📂";
            _logText = "HQ reels saved to mrb_cutter folder!";
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
        content: const Text("This feature will be available in the next update!, Stay Tuned"),
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
        title: const Text('MRB DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin),
            onPressed: () => showComingSoonDialog("Creator Profile"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // REPLACE 1: Waving hand ki jagah Bulb icon daala gaya hai
                    Icon(Icons.lightbulb_outline, color: Colors.amberAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Welcome, Creator. Select a movie to generate high-quality 9:16 reels.", 
                        style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: Icon(
                // REPLACE 2: Motion layers ki jagah Stars daale gaye hain
                _isProcessing ? Icons.sync_rounded : Icons.auto_awesome_rounded, 
                size: 90, 
                color: _watermarkPath != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
              ),
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
              child: SingleChildScrollView(
                child: Text("> $_logText", 
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontFamily: 'monospace')),
              ),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReelsScreen()));
                      },
                      icon: const Icon(Icons.folder_special, size: 18),
                      label: const Text("My Library"),
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
                label: const Text("Attach Brand Watermark"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 15),
              
              FilledButton.icon(
                onPressed: processMovie,
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: const Text("Process & Generate Reels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
