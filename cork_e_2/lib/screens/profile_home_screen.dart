import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/board_model.dart';
import '../widgets/polaroid_widget.dart';
import '../utils/theme.dart';
import 'individual_board_screen.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({super.key});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isEditingName = false;
  bool _isEditingBio = false;
  bool _isUploadingProfilePic = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePicture(String uid) async {
    setState(() => _isUploadingProfilePic = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final url = await _storage.uploadImage(bytes, uid);
      await _db.updateUserProfile(uid, photoURL: url);

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.currentUser?.updatePhotoURL(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfilePic = false);
    }
  }

  Future<void> _saveDisplayName(String uid) async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return;
    await _db.updateUserProfile(uid, displayName: name);
    if (mounted) setState(() => _isEditingName = false);
  }

  Future<void> _saveBio(String uid) async {
    await _db.updateUserBio(uid, _bioController.text.trim());
    if (mounted) setState(() => _isEditingBio = false);
  }

  Future<void> _createBoard(String uid) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Create New Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Board Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              await _db.createBoard(uid, title,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBoard(BoardModel board) async {
    final titleController = TextEditingController(text: board.title);
    final descriptionController = TextEditingController(text: board.description);
    Uint8List? newCoverPhotoBytes;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Edit Board'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title')),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.isNotEmpty) {
                    newCoverPhotoBytes = result.files.first.bytes;
                  }
                },
                child: const Text('Change Cover Photo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updates = {
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
              };
              if (newCoverPhotoBytes != null) {
                final url = await _storage.uploadImage(newCoverPhotoBytes!, board.ownerId);
                updates['coverPhotoUrl'] = url;
              }
              await _db.updateBoard(board.id, updates);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoard(BoardModel board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Delete Board?'),
        content: Text('Are you sure you want to delete "${board.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteBoard(board.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firebaseUser = authService.currentUser;
    if (firebaseUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: _db.getUserStream(firebaseUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return const Center(child: CircularProgressIndicator());

          if (_displayNameController.text.isEmpty && user.displayName != null) {
            _displayNameController.text = user.displayName!;
          }
          if (_bioController.text.isEmpty && user.bio != null) {
            _bioController.text = user.bio!;
          }

          return Column(
            children: [
              // Profile section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _updateProfilePicture(firebaseUser.uid),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                        ),
                        if (_isUploadingProfilePic)
                          const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isEditingName
                              ? Row(
                                  children: [
                                    Expanded(child: TextField(controller: _displayNameController)),
                                    IconButton(onPressed: () => _saveDisplayName(firebaseUser.uid), icon: const Icon(Icons.save))
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(user.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    IconButton(onPressed: () => setState(() => _isEditingName = true), icon: const Icon(Icons.edit))
                                  ],
                                ),
                          const SizedBox(height: 8),
                          _isEditingBio
                              ? Row(
                                  children: [
                                    Expanded(child: TextField(controller: _bioController, maxLines: 3)),
                                    IconButton(onPressed: () => _saveBio(firebaseUser.uid), icon: const Icon(Icons.save))
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: Text(user.bio ?? 'No bio', maxLines: 3, overflow: TextOverflow.ellipsis)),
                                    IconButton(onPressed: () => setState(() => _isEditingBio = true), icon: const Icon(Icons.edit))
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Boards section
              Expanded(
                child: StreamBuilder<List<BoardModel>>(
                  stream: _db.getUserBoards(firebaseUser.uid),
                  builder: (context, snapshot) {
                    final boards = snapshot.data ?? [];
                    return Stack(
                      children: [
                        for (final board in boards)
                          Positioned(
                            left: 20.0 + (boards.indexOf(board) * 30) % 200,
                            top: 50.0 + (boards.indexOf(board) * 40) % 200,
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IndividualBoardScreen(
                                    boardId: board.id,
                                    boardTitle: board.title,
                                  ),
                                ),
                              ),
                              onLongPress: () async {
                                final choice = await showModalBottomSheet<String>(
                                  context: context,
                                  builder: (_) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text('Edit Board'),
                                          onTap: () => Navigator.pop(context, 'edit')),
                                      ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Delete Board'),
                                          onTap: () => Navigator.pop(context, 'delete')),
                                    ],
                                  ),
                                );
                                if (choice == 'edit') await _editBoard(board);
                                if (choice == 'delete') await _deleteBoard(board);
                              },
                              child: PolaroidWidget(
                                imageUrl: board.coverPhotoUrl ?? '',
                                caption: board.title,
                                width: 140,
                                height: 180,
                                showPin: true,
                                onRotate: null, // optional: could implement board rotation
                              ),
                            ),
                          ),
                        // Add Board button
                        Positioned(
                          bottom: 32,
                          right: 32,
                          child: FloatingActionButton.extended(
                            onPressed: () => _createBoard(firebaseUser.uid),
                            backgroundColor: RetroTheme.blackMarker,
                            label: const Text('New Board', style: TextStyle(color: Colors.white)),
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
