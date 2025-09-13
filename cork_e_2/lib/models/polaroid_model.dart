class PolaroidModel {
  final String id;
  final String imageUrl;
  final String? audioUrl;
  final String? caption;
  final Map<String, double> position;
  final double rotation;
  final String? filterType;
  final DateTime createdAt;

  PolaroidModel({
    required this.id,
    required this.imageUrl,
    this.audioUrl,
    this.caption,
    required this.position,
    required this.rotation,
    this.filterType,
    required this.createdAt,
  });

  factory PolaroidModel.fromMap(Map<String, dynamic> data, String id) {
    return PolaroidModel(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      audioUrl: data['audioUrl'],
      caption: data['caption'],
      position: Map<String, double>.from(data['position'] ?? {'x': 0, 'y': 0}),
      rotation: (data['rotation'] ?? 0).toDouble(),
      filterType: data['filterType'],
      createdAt: (data['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'caption': caption,
      'position': position,
      'rotation': rotation,
      'filterType': filterType,
      'createdAt': createdAt,
    };
  }

  PolaroidModel copyWith({
    String? caption,
    Map<String, double>? position,
    double? rotation,
    String? filterType,
    String? audioUrl,
  }) {
    return PolaroidModel(
      id: id,
      imageUrl: imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      caption: caption ?? this.caption,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      filterType: filterType ?? this.filterType,
      createdAt: createdAt,
    );
  }
}