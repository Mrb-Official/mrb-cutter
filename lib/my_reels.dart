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
    _loadAssetsFromStorage();
  }

  // Optimized function to scan local directory for processed assets
  Future<void> _loadAssetsFromStorage() async {
    setState(() => _isLoading = true);
    
    // Target directory for MRB processed reels
    Directory downloadDir = Directory('/storage/emulated/0/Download');
    List<FileSystemEntity> tempAssets = [];

    try {
      if (await downloadDir.exists()) {
        List<FileSystemEntity> allEntities = downloadDir.listSync();
        for (var entity in allEntities) {
          // Filtering directories with MRB naming convention
          if (entity is Directory && entity.path.contains('MRB_')) {
            // Extracting valid MP4 media files
            tempAssets.addAll(
              entity.listSync().where((file) => file.path.endsWith('.mp4'))
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Storage Scan Exception: $e");
    }

    setState(() {
      _reelsList = tempAssets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Accessing system color scheme for consistency
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ASSET ARCHIVE', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAssetsFromStorage,
            tooltip: "Re-scan Storage",
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 5,
              ),
            )
          : _reelsList.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildAssetList(colorScheme),
    );
  }

  // UI for Empty State
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: colorScheme.outline),
          const SizedBox(height: 20),
          const Text(
            "NO ASSETS DETECTED",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Your processed media library is currently empty. Initialize the cutting process to generate assets.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  // UI for Media Asset List
  Widget _buildAssetList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reelsList.length,
      itemBuilder: (context, index) {
        File file = File(_reelsList[index].path);
        String fileName = file.path.split('/').last;
        String parentFolder = file.parent.path.split('/').last;
        
        // Calculating high-precision file size
        double fileSizeMB = file.lengthSync() / (1024 * 1024);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_circle_filled_rounded, color: colorScheme.onPrimaryContainer),
            ),
            title: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Source: $parentFolder\nSize: ${fileSizeMB.toStringAsFixed(2)} MB",
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
            trailing: Icon(Icons.open_in_new_rounded, size: 20, color: colorScheme.primary),
            onTap: () {
              // Executing system-level file handler
              OpenFile.open(file.path);
            },
          ),
        );
      },
    );
  }
}