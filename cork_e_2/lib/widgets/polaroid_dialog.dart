import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/polaroid_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../utils/image_filters.dart';
import 'polaroid_widget.dart';

class PolaroidDialog extends StatefulWidget {
  final PolaroidModel polaroid;
  final String boardId;
  final Function(PolaroidModel) onUpdate;
  final VoidCallback onDelete;

  const PolaroidDialog({
    super.key,
    required this.polaroid,
    required this.boardId,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<PolaroidDialog> createState() => _PolaroidDialogState();
}

class _PolaroidDialogState extends State<PolaroidDialog> {
  late TextEditingController _captionController;
  late TextEditingController _notesController;
  late String _selectedFilter;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StorageService _storage = StorageService();
  final DatabaseService _db = DatabaseService();
  bool _isPlaying = false;
  bool _isUploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.polaroid.caption);
    _notesController = TextEditingController();
    _selectedFilter = widget.polaroid.filterType ?? 'none';
    
    // Auto-play audio if exists
    if (widget.polaroid.audioUrl != null) {
      _playAudio();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _notesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.polaroid.audioUrl == null) return;
    
    try {
      await _audioPlayer.play(UrlSource(widget.polaroid.audioUrl!));
      setState(() => _isPlaying = true);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlaying = false);
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _playAudio();
    }
  }

  Future<void> _uploadAudio() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    setState(() => _isUploadingAudio = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        
        if (fileBytes != null) {
          final audioUrl = await _storage.uploadAudio(fileBytes, userId);
          
          final updatedPolaroid = widget.polaroid.copyWith(audioUrl: audioUrl);
          widget.onUpdate(updatedPolaroid);
          
          await _db.updatePolaroid(
            widget.boardId,
            widget.polaroid.id,
            {'audioUrl': audioUrl},
          );
          
          if (mounted) {
            setState(() {
              _isUploadingAudio = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio uploaded successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAudio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading audio: $e')),
        );
      }
    }
  }

  void _saveChanges() {
    final updatedPolaroid = widget.polaroid.copyWith(
      caption: _captionController.text,
      filterType: _selectedFilter == 'none' ? null : _selectedFilter,
    );
    
    widget.onUpdate(updatedPolaroid);
    
    _db.updatePolaroid(
      widget.boardId,
      widget.polaroid.id,
      {
        'caption': _captionController.text,
        'filterType': _selectedFilter == 'none' ? null : _selectedFilter,
      },
    );
    
    Navigator.pop(context);
  }

  void _deletePolaroid() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Delete Polaroid?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close polaroid dialog
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: RetroTheme.corkBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Left side - Polaroid preview
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Polaroid with pin
                        Transform.scale(
                          scale: 1.5,
                          child: Transform.rotate(
                            angle: -0.05,
                            child: PolaroidWidget(
                              imageUrl: widget.polaroid.imageUrl,
                              caption: _captionController.text,
                              filterType: _selectedFilter == 'none' ? null : _selectedFilter,
                              showPin: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right side - Controls and sticky notes
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comments/Reactions banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
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
                            'comments/reactions',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Sticky notes grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                            children: [
                              // Caption sticky note
                              _buildStickyNote(
                                color: RetroTheme.blueSticky,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Caption',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _captionController,
                                        maxLines: 3,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        decoration: const InputDecoration(
                                          hintText: 'Add a caption...',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Filter selection sticky note
                              _buildStickyNote(
                                color: RetroTheme.blueSticky,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filter',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            _buildFilterOption('none', 'Original'),
                                            _buildFilterOption('sepia', 'Sepia'),
                                            _buildFilterOption('blackAndWhite', 'B&W'),
                                            _buildFilterOption('vintage', 'Vintage'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Audio sticky note
                              _buildStickyNote(
                                color: RetroTheme.blueSticky,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Audio Memory',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (widget.polaroid.audioUrl != null) ...[
                                      IconButton(
                                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                        onPressed: _toggleAudio,
                                      ),
                                      TextButton(
                                        onPressed: _uploadAudio,
                                        child: const Text('Replace'),
                                      ),
                                    ] else ...[
                                      ElevatedButton.icon(
                                        onPressed: _isUploadingAudio ? null : _uploadAudio,
                                        icon: _isUploadingAudio
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.upload_file),
                                        label: Text(_isUploadingAudio ? 'Uploading...' : 'Upload'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: RetroTheme.blackMarker,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Notes sticky note
                              _buildStickyNote(
                                color: RetroTheme.blueSticky,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _notesController,
                                        maxLines: null,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        decoration: const InputDecoration(
                                          hintText: 'Add notes...',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: _deletePolaroid,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                            ElevatedButton.icon(
                              onPressed: _saveChanges,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RetroTheme.blackMarker,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, size: 32),
                onPressed: () {
                  _audioPlayer.stop();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyNote({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFilterOption(String value, String label) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedFilter,
      onChanged: (newValue) {
        setState(() {
          _selectedFilter = newValue!;
        });
      },
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}