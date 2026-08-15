class VoiceNote {
  final String id;
  final String title;
  final String filePath;
  final Duration duration;
  final DateTime createdAt;

  VoiceNote({
    required this.id,
    required this.title,
    required this.filePath,
    required this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'durationMs': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      duration: Duration(milliseconds: (map['durationMs'] as num).toInt()),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
