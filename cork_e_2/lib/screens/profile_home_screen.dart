import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/board_model.dart';
import '../widgets/corkboard_background.dart';
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
  final _bioController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isEditingBio = false;
  bool _isEditingName = false;
  bool _isUploadingProfilePic = false;

  @override
  void dispose() {
    _bioController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveBio(String uid) async {
    await _db.updateUserBio(uid, _bioController.text);
    setState(() => _isEditingBio = false);
  }

  Future<void> _saveDisplayName(String uid) async {
    await _db.updateUserProfile(uid, displayName: _displayNameController.text);
    setState(() => _isEditingName = false);
  }

  Future<void> _updateProfilePicture(String uid) async {
    setState(() => _isUploadingProfilePic = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        
        if (fileBytes != null) {
          final photoURL = await _storage.uploadImage(fileBytes, uid);
          await _db.updateUserProfile(uid, photoURL: photoURL);
          
          // Update Firebase Auth profile
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.currentUser?.updatePhotoURL(photoURL);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingProfilePic = false);
    }
  }

  Future<void> _createNewBoard(BuildContext context, String userId) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: Text(
          'Create New Board',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Board Title',
                filled: true,
                fillColor: Colors.white,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                try {
                  final boardId = await _db.createBoard(
                    titleController.text,
                    userId,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IndividualBoardScreen(
                          boardId: boardId,
                          boardTitle: titleController.text,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating board: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showBoardOptions(BuildContext context, BoardModel board) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RetroTheme.yellowSticky,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Board'),
              onTap: () {
                Navigator.pop(context);
                _renameBoard(context, board);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Board', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteBoard(context, board);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameBoard(BuildContext context, BoardModel board) async {
    final titleController = TextEditingController(text: board.title);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Rename Board'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'New Title',
            filled: true,
            fillColor: Colors.white,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                try {
                  await _db.updateBoard(board.id, {'title': titleController.text});
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error renaming board: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoard(BuildContext context, BoardModel board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: const Text('Delete Board?'),
        content: Text('Are you sure you want to delete "${board.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _db.deleteBoard(board.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting board: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CorkboardBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 400,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // CorkE Note
                    Positioned(
                      top: 15,
                      left: 15,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Image.asset(
                          'assets/images/corke_note.png',
                          width: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Profile Polaroid Frame
                    Positioned(
                      top: 90,
                      left: 30,
                      child: Transform.rotate(
                        angle: -0.05,
                        child: Container(
                          width: 250,
                          height: 300,
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/polaroid_frame.png',
                                fit: BoxFit.fill,
                              ),
                              Positioned(
                                top: 25,
                                left: 25,
                                right: 25,
                                height: 190,
                                child: GestureDetector(
                                  onTap: () => _updateProfilePicture(currentUser.uid),
                                  child: Container(
                                    color: Colors.black,
                                    child: Stack(
                                      children: [
                                        StreamBuilder<UserModel?>(
                                          stream: _db.getUserStream(currentUser.uid),
                                          builder: (context, snapshot) {
                                            final user = snapshot.data;
                                            final photoURL = user?.photoURL ?? currentUser.photoURL;
                                            
                                            return photoURL != null
                                                ? CachedNetworkImage(
                                                    imageUrl: photoURL,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    placeholder: (context, url) =>
                                                        const Center(child: CircularProgressIndicator()),
                                                    errorWidget: (context, url, error) =>
                                                        const Icon(Icons.person, size: 70, color: Colors.white),
                                                  )
                                                : const Icon(Icons.person, size: 70, color: Colors.white);
                                          },
                                        ),
                                        if (_isUploadingProfilePic)
                                          Container(
                                            color: Colors.black54,
                                            child: const Center(
                                              child: CircularProgressIndicator(color: Colors.white),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 25,
                                left: 0,
                                right: 0,
                                child: StreamBuilder<UserModel?>(
                                  stream: _db.getUserStream(currentUser.uid),
                                  builder: (context, snapshot) {
                                    final user = snapshot.data;
                                    final displayName = user?.displayName ?? currentUser.displayName ?? currentUser.email ?? 'Username';
                                    
                                    if (_displayNameController.text.isEmpty && user?.displayName != null) {
                                      _displayNameController.text = user!.displayName!;
                                    }

                                    return GestureDetector(
                                      onTap: () => setState(() => _isEditingName = true),
                                      child: _isEditingName
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: TextField(
                                                controller: _displayNameController,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  fontFamily: 'Handwritten',
                                                ),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (_) => _saveDisplayName(currentUser.uid),
                                                autofocus: true,
                                              ),
                                            )
                                          : Text(
                                              displayName,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontFamily: 'Handwritten',
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                              // Pink tape
                              Positioned(
                                top: 5,
                                right: 50,
                                child: Transform.rotate(
                                  angle: 0.1,
                                  child: Image.asset(
                                    'assets/images/tape_pink.png',
                                    width: 50,
                                    height: 20,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bio Note
                    Positioned(
                      top: 70,
                      right: 30,
                      child: Transform.rotate(
                        angle: 0.03,
                        child: Container(
                          width: 400,
                          height: 350,
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/torn_paper_note.png',
                                fit: BoxFit.fill,
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                                  child: StreamBuilder<UserModel?>(
                                    stream: _db.getUserStream(currentUser.uid),
                                    builder: (context, snapshot) {
                                      final user = snapshot.data;

                                      if (_bioController.text.isEmpty && user?.bio != null) {
                                        _bioController.text = user!.bio!;
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                user?.displayName ?? currentUser.displayName ?? 'User',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontFamily: 'Handwritten',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(_isEditingBio ? Icons.save : Icons.edit, size: 20),
                                                onPressed: () {
                                                  if (_isEditingBio) {
                                                    _saveBio(currentUser.uid);
                                                  } else {
                                                    setState(() => _isEditingBio = true);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _isEditingBio
                                              ? Expanded(
                                                  child: TextField(
                                                    controller: _bioController,
                                                    maxLines: null,
                                                    expands: true,
                                                    maxLength: 250,
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      fontFamily: 'Handwritten',
                                                    ),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Biography here: Limited to 250 char',
                                                      border: InputBorder.none,
                                                      contentPadding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                )
                                              : Expanded(
                                                  child: Text(
                                                    user?.bio ?? 'Biography here: Limited to 250 char',
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      fontFamily: 'Handwritten',
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Orange tape decorations
                              Positioned(
                                top: 5,
                                left: 100,
                                child: Transform.rotate(
                                  angle: 0.05,
                                  child: Image.asset(
                                    'assets/images/tape_orange.png',
                                    width: 80,
                                    height: 30,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                left: 50,
                                child: Transform.rotate(
                                  angle: -0.1,
                                  child: Image.asset(
                                    'assets/images/tape_orange.png',
                                    width: 60,
                                    height: 25,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 50,
                                child: Transform.rotate(
                                  angle: 0.15,
                                  child: Image.asset(
                                    'assets/images/tape_orange.png',
                                    width: 70,
                                    height: 28,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black, size: 30),
                  onPressed: () async {
                    await authService.signOut();
                  },
                ),
              ],
            ),
            
            // Boards Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: [
                    Transform.rotate(
                      angle: -0.02,
                      child: Image.asset(
                        'assets/images/boards_banner.png',
                        width: 250,
                        height: 50,
                        fit: BoxFit.fill,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _createNewBoard(context, currentUser.uid),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('New Board'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RetroTheme.blackMarker,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Boards Grid
            StreamBuilder<List<BoardModel>>(
              stream: _db.getUserBoards(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading boards: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final boards = snapshot.data ?? [];
                
                if (boards.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dashboard, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No boards yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _createNewBoard(context, currentUser.uid),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Your First Board'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RetroTheme.blackMarker,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final board = boards[index];
                        return _buildBoardCard(context, board);
                      },
                      childCount: boards.length,
                    ),
                  ),
                );
              },
            ),
            
            // Add some bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context, BoardModel board) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualBoardScreen(
              boardId: board.id,
              boardTitle: board.title,
            ),
          ),
        );
      },
      onLongPress: () => _showBoardOptions(context, board),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pin decoration
            Positioned(
              top: -5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: RetroTheme.redPin,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    color: Colors.black,
                    child: board.coverPhotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: board.coverPhotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                Center(
                                  child: Text(
                                    'cover photo',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          )
                        : Center(
                            child: Text(
                              'cover photo',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    board.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}