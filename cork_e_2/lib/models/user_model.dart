class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      bio: data['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
    };
  }
}