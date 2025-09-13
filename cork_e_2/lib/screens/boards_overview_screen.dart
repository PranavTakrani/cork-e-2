import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/board_model.dart';
import '../widgets/corkboard_background.dart';
import '../utils/theme.dart';
import 'individual_board_screen.dart';

class BoardsOverviewScreen extends StatefulWidget {
  const BoardsOverviewScreen({super.key});

  @override
  State<BoardsOverviewScreen> createState() => _BoardsOverviewScreenState();
}

class _BoardsOverviewScreenState extends State<BoardsOverviewScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _createNewBoard(BuildContext context, String userId) async {
    final titleController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroTheme.yellowSticky,
        title: Text(
          'Create New Board',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Board Title',
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
                final boardId = await _db.createBoard(
                  titleController.text,
                  userId,
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
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RetroTheme.blackMarker),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: CorkboardBackground(
        child: Column(
          children: [
            const SizedBox(height: 80),
            
            // Header with user info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RetroTheme.whiteNote,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    currentUser.displayName ?? 'Username',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                
                const SizedBox(width: 32),
                
                Container(
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
                    '↓ BOARDS ↓',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Boards Grid
            Expanded(
              child: StreamBuilder<List<BoardModel>>(
                stream: _db.getUserBoards(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final boards = snapshot.data ?? [];
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: boards.length + 1,
                    itemBuilder: (context, index) {
                      // Add new board button
                      if (index == 0) {
                        return _buildAddBoardCard(context, currentUser.uid);
                      }
                      
                      final board = boards[index - 1];
                      return _buildBoardCard(context, board);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBoardCard(BuildContext context, String userId) {
    return GestureDetector(
      onTap: () => _createNewBoard(context, userId),
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                color: Colors.grey[300],
                child: const Icon(
                  Icons.add,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Create New Board',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
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
                await _db.updateBoard(board.id, {'title': titleController.text});
                if (mounted) Navigator.pop(context);
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
      await _db.deleteBoard(board.id);
    }
  }
}