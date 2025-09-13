import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/polaroid_model.dart';
import '../widgets/corkboard_background.dart';
import '../widgets/draggable_polaroid.dart';
import '../utils/theme.dart';

class IndividualBoardScreen extends StatefulWidget {
  final String boardId;
  final String boardTitle;

  const IndividualBoardScreen({
    super.key,
    required this.boardId,
    required this.boardTitle,
  });

  @override
  State<IndividualBoardScreen> createState() => _IndividualBoardScreenState();
}

class _IndividualBoardScreenState extends State<IndividualBoardScreen> {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();
  bool _isUploading = false;

  Future<void> _uploadImage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        
        if (fileBytes != null) {
          // Show developing animation
          _showDevelopingAnimation();
          
          // Upload image
          final imageUrl = await _storage.uploadImage(fileBytes, userId);
          
          // Create polaroid with random position
          final polaroid = PolaroidModel(
            id: '',
            imageUrl: imageUrl,
            position: {
              'x': 100.0 + (DateTime.now().millisecondsSinceEpoch % 500),
              'y': 100.0 + (DateTime.now().millisecondsSinceEpoch % 300),
            },
            rotation: -15 + (DateTime.now().millisecondsSinceEpoch % 30).toDouble(),
            createdAt: DateTime.now(),
          );
          
          await _db.addPolaroid(widget.boardId, polaroid);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showDevelopingAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
        
        return Center(
          child: Container(
            width: 200,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  margin: const EdgeInsets.all(10),
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Developing...',
                    style: TextStyle(
                      fontFamily: 'Kalam',
                      fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CorkboardBackground(
        child: Stack(
          children: [
            // Board Title
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  decoration: BoxDecoration(
                    color: RetroTheme.tape,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.boardTitle,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ),
            ),

            // Polaroids
            StreamBuilder<List<PolaroidModel>>(
              stream: _db.getBoardPolaroids(widget.boardId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final polaroids = snapshot.data ?? [];
                
                return Stack(
                  children: polaroids.map((polaroid) {
                    return DraggablePolaroid(
                      key: ValueKey(polaroid.id),
                      polaroid: polaroid,
                      boardId: widget.boardId,
                      onUpdate: (updatedPolaroid) {
                        _db.updatePolaroid(
                          widget.boardId,
                          polaroid.id,
                          updatedPolaroid.toMap(),
                        );
                      },
                      onDelete: () {
                        _db.deletePolaroid(widget.boardId, polaroid.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),

            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Add photo button
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton.extended(
                onPressed: _isUploading ? null : _uploadImage,
                backgroundColor: RetroTheme.blackMarker,
                label: Text(
                  _isUploading ? 'Uploading...' : 'Add Photo',
                  style: const TextStyle(color: Colors.white),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_a_photo, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}