import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImage(Uint8List imageData, String userId) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('images/$userId/$fileName');
      
      final UploadTask uploadTask = ref.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<String> uploadAudio(Uint8List audioData, String userId) async {
    try {
      final String fileName = '${_uuid.v4()}.mp3';
      final Reference ref = _storage.ref().child('audio/$userId/$fileName');
      
      final UploadTask uploadTask = ref.putData(
        audioData,
        SettableMetadata(contentType: 'audio/mpeg'),
      );
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // File might not exist or already deleted
      print('Error deleting file: $e');
    }
  }
}