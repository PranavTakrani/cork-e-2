class BoardModel {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final DateTime createdAt;
  final String? coverPhotoUrl;

  BoardModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    required this.createdAt,
    this.coverPhotoUrl,
  });

  factory BoardModel.fromMap(Map<String, dynamic> data, String id) {
    return BoardModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? 'Untitled Board',
      description: data['description'],
      createdAt: (data['createdAt'] as dynamic).toDate(),
      coverPhotoUrl: data['coverPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'coverPhotoUrl': coverPhotoUrl,
    };
  }
}