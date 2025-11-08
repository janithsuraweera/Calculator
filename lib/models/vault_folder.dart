/// Vault folder model for organizing files
class VaultFolder {
  final String id;
  final String name;
  final String? parentFolderId;
  final DateTime createdAt;
  final bool isHidden;

  VaultFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentFolderId': parentFolderId,
      'createdAt': createdAt.toIso8601String(),
      'isHidden': isHidden,
    };
  }

  factory VaultFolder.fromJson(Map<String, dynamic> json) {
    return VaultFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  VaultFolder copyWith({
    String? id,
    String? name,
    String? parentFolderId,
    DateTime? createdAt,
    bool? isHidden,
  }) {
    return VaultFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      createdAt: createdAt ?? this.createdAt,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
