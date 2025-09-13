import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/board_model.dart';
import '../models/polaroid_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User operations
  Future<void> createOrUpdateUser(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
  Future<String> createBoard(String title, String ownerId) async {
    final docRef = await _db.collection('boards').add({
      'title': title,
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<BoardModel>> getUserBoards(String uid) {
    return _db
        .collection('boards')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BoardModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateBoard(String boardId, Map<String, dynamic> data) async {
    await _db.collection('boards').doc(boardId).update(data);
  }

  Future<void> deleteBoard(String boardId) async {
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
  }

  // Polaroid operations
  Future<String> addPolaroid(String boardId, PolaroidModel polaroid) async {
    final docRef = await _db
        .collection('boards')
        .doc(boardId)
        .collection('polaroids')
        .add(polaroid.toMap());
    return docRef.id;
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
            .toList());
  }

  Future<void> updatePolaroid(
      String boardId, String polaroidId, Map<String, dynamic> data) async {
    await _db
        .collection('boards')
        .doc(boardId)
        .collection('polaroids')
        .doc(polaroidId)
        .update(data);
  }

  Future<void> deletePolaroid(String boardId, String polaroidId) async {
    await _db
        .collection('boards')
        .doc(boardId)
        .collection('polaroids')
        .doc(polaroidId)
        .delete();
  }
}