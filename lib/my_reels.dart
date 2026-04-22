import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class MyReelsScreen extends StatefulWidget {
  const MyReelsScreen({super.key});

  @override
  State<MyReelsScreen> createState() => _MyReelsScreenState();
}

class _MyReelsScreenState extends State<MyReelsScreen> {
  List<FileSystemEntity> _reelsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  // Phone me se Reels dhoondhne wala Smart Function
  Future<void> _loadReels() async {
    Directory downloadDir = Directory('/storage/emulated/0/Download');
    List<FileSystemEntity> tempReels = [];

    if (await downloadDir.exists()) {
      // Pata lagao ki kitne MRB_ wale folders hain
      List<FileSystemEntity> allFiles = downloadDir.listSync();
      for (var entity in allFiles) {
        if (entity is Directory && entity.path.contains('MRB_')) {
          // Folder ke andar ki saari mp4 files utha lo
          tempReels.addAll(entity.listSync().where((file) => file.path.endsWith('.mp4')));
        }
      }
    }

    setState(() {
      _reelsList = tempReels;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('MY VIRAL REELS 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _reelsList.isEmpty
              ? const Center(
                  child: Text("Bhai abhi tak koi Reel cut nahi ki! ✂️", 
                    style: TextStyle(color: Colors.white54, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reelsList.length,
                  itemBuilder: (context, index) {
                    File file = File(_reelsList[index].path);
                    String fileName = file.path.split('/').last;
                    String folderName = file.parent.path.split('/').last;
                    
                    // File size in MB calculation
                    double sizeInMb = file.lengthSync() / (1024 * 1024);

                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.cyanAccent,
                          child: Icon(Icons.play_arrow_rounded, color: Colors.black87),
                        ),
                        title: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("$folderName • ${sizeInMb.toStringAsFixed(1)} MB", 
                          style: const TextStyle(color: Colors.white54)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 16),
                        onTap: () {
                          // Click karte hi phone ke native video player me chalega
                          OpenFile.open(file.path);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}