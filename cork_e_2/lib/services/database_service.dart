import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/board_model.dart';
import '../models/polaroid_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User operations
  Future<void> createOrUpdateUser(User user, {String? customDisplayName}) async {
    final userData = {
      'email': user.email,
      'displayName': customDisplayName ?? user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    };
    
    await _db.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, {String? displayName, String? photoURL, String? bio}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoURL != null) updates['photoURL'] = photoURL;
    if (bio != null) updates['bio'] = bio;
    
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> updateUserBio(String uid, String bio) async {
    await _db.collection('users').doc(uid).update({'bio': bio});
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Board operations
  Future<String> createBoard(String title, String ownerId, {String? description}) async {
    try {
      final docRef = await _db.collection('boards').add({
        'title': title,
        'description': description,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
        'coverPhotoUrl': null, // Will be set later when first photo is added
      });
      return docRef.id;
    } catch (e) {
      print('Error creating board: $e');
      rethrow;
    }
  }

  Stream<List<BoardModel>> getUserBoards(String uid) {
    return _db
        .collection('boards')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BoardModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
          print('Error fetching user boards: $error');
          return <BoardModel>[];
        });
  }

  Future<void> updateBoard(String boardId, Map<String, dynamic> data) async {
    try {
      await _db.collection('boards').doc(boardId).update(data);
    } catch (e) {
      print('Error updating board: $e');
      rethrow;
    }
  }

  Future<void> updateBoardCoverPhoto(String boardId, String coverPhotoUrl) async {
    try {
      await _db.collection('boards').doc(boardId).update({
        'coverPhotoUrl': coverPhotoUrl,
      });
    } catch (e) {
      print('Error updating board cover photo: $e');
    }
  }

  Future<void> deleteBoard(String boardId) async {
    try {
      // Delete all polaroids first
      final polaroids = await _db
          .collection('boards')
          .doc(boardId)
          .collection('polaroids')
          .get();
      
      for (var doc in polaroids.docs) {
        await doc.reference.delete();
      }
      
      // Delete the board
      await _db.collection('boards').doc(boardId).delete();
    } catch (e) {
      print('Error deleting board: $e');
      rethrow;
    }
  }

  // Polaroid operations
  Future<String> addPolaroid(String boardId, PolaroidModel polaroid) async {
    try {
      final docRef = await _db
          .collection('boards')
          .doc(boardId)
          .collection('polaroids')
          .add(polaroid.toMap());
      
      // Update board cover photo if it's the first polaroid
      final boardDoc = await _db.collection('boards').doc(boardId).get();
      if (boardDoc.exists && boardDoc.data()?['coverPhotoUrl'] == null) {
        await updateBoardCoverPhoto(boardId, polaroid.imageUrl);
      }
      
      return docRef.id;
    } catch (e) {
      print('Error adding polaroid: $e');
      rethrow;
    }
  }

  Stream<List<PolaroidModel>> getBoardPolaroids(String boardId) {
    return _db
        .collection('boards')
        .doc(boardId)
        .collection('polaroids')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PolaroidModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
          print('Error fetching board polaroids: $error');
          return <PolaroidModel>[];
        });
  }

  Future<void> updatePolaroid(
      String boardId, String polaroidId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('boards')
          .doc(boardId)
          .collection('polaroids')
          .doc(polaroidId)
          .update(data);
    } catch (e) {
      print('Error updating polaroid: $e');
      rethrow;
    }
  }

  Future<void> deletePolaroid(String boardId, String polaroidId) async {
    try {
      await _db
          .collection('boards')
          .doc(boardId)
          .collection('polaroids')
          .doc(polaroidId)
          .delete();
    } catch (e) {
      print('Error deleting polaroid: $e');
      rethrow;
    }
  }
}