/// Vault note model for storing notes in vault
class VaultNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reminderDate;
  final String? folderId;
  final bool isHidden;
  final List<String> tags;

  VaultNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.reminderDate,
    this.folderId,
    this.isHidden = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'folderId': folderId,
      'isHidden': isHidden,
      'tags': tags,
    };
  }

  factory VaultNote.fromJson(Map<String, dynamic> json) {
    return VaultNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
      folderId: json['folderId'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  VaultNote copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderDate,
    String? folderId,
    bool? isHidden,
    List<String>? tags,
  }) {
    return VaultNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderDate: reminderDate ?? this.reminderDate,
      folderId: folderId ?? this.folderId,
      isHidden: isHidden ?? this.isHidden,
      tags: tags ?? this.tags,
    );
  }

  bool get hasReminder => reminderDate != null;
  bool get isReminderDue =>
      reminderDate != null && reminderDate!.isBefore(DateTime.now());
}
