import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../widgets/corkboard_background.dart';
import '../utils/theme.dart';
import 'boards_overview_screen.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({super.key});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  final DatabaseService _db = DatabaseService();
  final _bioController = TextEditingController();
  bool _isEditingBio = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveBio(String uid) async {
    await _db.updateUserBio(uid, _bioController.text);
    setState(() => _isEditingBio = false);
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
        child: Stack(
          children: [
            // Cork texture note in corner
            Positioned(
              top: 20,
              left: 20,
              child: Transform.rotate(
                angle: -0.1,
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                    'CorkE',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Profile Polaroid
                    Container(
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
                          // Photo area
                          Container(
                            width: 250,
                            height: 250,
                            margin: const EdgeInsets.all(12),
                            color: Colors.black,
                            child: currentUser.photoURL != null
                                ? CachedNetworkImage(
                                    imageUrl: currentUser.photoURL!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person, size: 100, color: Colors.white),
                                  )
                                : const Icon(Icons.person, size: 100, color: Colors.white),
                          ),
                          
                          // Username caption
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
                            child: Text(
                              currentUser.displayName ?? currentUser.email ?? 'Username',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bio Note
                    StreamBuilder<UserModel?>(
                      stream: _db.getUserStream(currentUser.uid),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        
                        if (_bioController.text.isEmpty && user?.bio != null) {
                          _bioController.text = user!.bio!;
                        }

                        return Transform.rotate(
                          angle: 0.02,
                          child: Container(
                            width: 400,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/images/torn_paper.png'),
                                fit: BoxFit.fill,
                              ),
                              color: RetroTheme.whiteNote,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'About Me',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    IconButton(
                                      icon: Icon(_isEditingBio ? Icons.save : Icons.edit),
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
                                const SizedBox(height: 8),
                                _isEditingBio
                                    ? TextField(
                                        controller: _bioController,
                                        maxLines: 4,
                                        maxLength: 250,
                                        decoration: const InputDecoration(
                                          hintText: 'Tell us about yourself...',
                                          border: OutlineInputBorder(),
                                        ),
                                      )
                                    : Text(
                                        user?.bio ?? 'Biography here: Limited to 250 char',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Friends Section (placeholder)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: RetroTheme.blackMarker,
                      child: Text(
                        'FRIENDS',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boards Banner
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BoardsOverviewScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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
                    ),
                  ],
                ),
              ),
            ),

            // Sign out button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}