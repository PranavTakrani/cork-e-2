import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../widgets/corkboard_background.dart';
import '../utils/theme.dart'; // Assuming RetroTheme is defined here
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
            // CorkE Note (as an image)
            Positioned(
              top: 15, // Adjusted position
              left: 15, // Adjusted position
              child: Transform.rotate(
                angle: -0.1, // Slight rotation
                child: Image.asset(
                  'assets/images/corke_note.png', // Assuming you have this asset
                  width: 80, // Adjust size as needed
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Profile Polaroid Frame
            Positioned(
              top: 90, // Position relative to mockup
              left: 30, // Position relative to mockup
              child: Transform.rotate(
                angle: -0.05, // Slight rotation
                child: Container(
                  width: 250, // Match the polaroid frame size
                  height: 300, // Match the polaroid frame size
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/polaroid_frame.png', // Your polaroid frame asset
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        top: 25, // Adjust to fit inside the photo area of the frame
                        left: 25, // Adjust to fit inside the photo area of the frame
                        right: 25, // Adjust to fit inside the photo area of the frame
                        height: 190, // Adjust height for the photo area
                        child: Container(
                          color: Colors.black, // Background for the image
                          child: currentUser.photoURL != null
                              ? CachedNetworkImage(
                                  imageUrl: currentUser.photoURL!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.person, size: 70, color: Colors.white),
                                )
                              : const Icon(Icons.person, size: 70, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 25, // Position username at the bottom of the polaroid
                        left: 0,
                        right: 0,
                        child: Text(
                          currentUser.displayName ?? currentUser.email ?? 'Username',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Handwritten', // Use a custom handwritten font
                          ),
                        ),
                      ),
                      // Pink tape for the polaroid
                      Positioned(
                        top: 5,
                        right: 50,
                        child: Transform.rotate(
                          angle: 0.1, // Slight rotation for the tape
                          child: Image.asset(
                            'assets/images/tape_pink.png', // Pink tape asset
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

            // Bio Note (as an image)
            Positioned(
              top: 70, // Position relative to mockup
              right: 30, // Position relative to mockup
              child: Transform.rotate(
                angle: 0.03, // Slight rotation
                child: Container(
                  width: 400, // Size of your note asset
                  height: 350, // Size of your note asset
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/torn_paper_note.png', // Your torn paper asset
                        fit: BoxFit.fill,
                      ),
                      // Content of the bio note
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 60, 40, 40), // Adjust padding to fit inside the note image
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
                                        user?.displayName ?? currentUser.email ?? 'name here', // Display name here as per mockup
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontFamily: 'Handwritten', // Use custom handwritten font
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
                                            maxLines: null, // Allow multiple lines
                                            expands: true, // Allow it to fill available space
                                            maxLength: 250,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontFamily: 'Handwritten', // Use custom font for input
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Biography here: Limited to 250 char',
                                              border: InputBorder.none, // No border for handwritten feel
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                      )
                                      : Expanded(
                                        child: Text(
                                            user?.bio ?? 'Biography here: Limited to 250 char',
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontFamily: 'Handwritten', // Use custom handwritten font
                                            ),
                                          ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // Orange tape for the bio note
                      Positioned(
                        top: 5,
                        left: 100,
                        child: Transform.rotate(
                          angle: 0.05, // Slight rotation for the tape
                          child: Image.asset(
                            'assets/images/tape_orange.png', // Orange tape asset
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
                          angle: -0.1, // Slight rotation for the tape
                          child: Image.asset(
                            'assets/images/tape_orange.png', // Orange tape asset
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
                          angle: 0.15, // Slight rotation for the tape
                          child: Image.asset(
                            'assets/images/tape_orange.png', // Orange tape asset
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

            // Friends Section Banner (as an image)
            Positioned(
              top: 420, // Position relative to mockup
              right: 80, // Position relative to mockup
              child: Transform.rotate(
                angle: -0.02, // Slight rotation
                child: Image.asset(
                  'assets/images/friends_banner.png', // Your friends banner asset
                  width: 300, // Adjust size as needed
                  height: 50, // Adjust size as needed
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // Boards Banner (as an image)
            Positioned(
              bottom: 100, // Position relative to mockup
              left: 400, // Position relative to mockup
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BoardsOverviewScreen(),
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: -0.05, // Slight rotation
                  child: Image.asset(
                    'assets/images/boards_banner.png', // Your boards banner asset
                    width: 250, // Adjust size as needed
                    height: 50, // Adjust size as needed
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),

            // Sign out button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.black, size: 30),
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