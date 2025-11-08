import 'package:flutter/material.dart';

/// Vault file model for storing files in vault
class VaultFile {
  final String id;
  final String name;
  final String path;
  final VaultFileType type;
  final String? folderId;
  final DateTime createdAt;
  final int size; // in bytes
  final bool isHidden;

  VaultFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.folderId,
    required this.createdAt,
    required this.size,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.toString().split('.').last,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'size': size,
      'isHidden': isHidden,
    };
  }

  factory VaultFile.fromJson(Map<String, dynamic> json) {
    return VaultFile(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: VaultFileType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => VaultFileType.other,
      ),
      folderId: json['folderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      size: json['size'] as int,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  VaultFile copyWith({
    String? id,
    String? name,
    String? path,
    VaultFileType? type,
    String? folderId,
    DateTime? createdAt,
    int? size,
    bool? isHidden,
  }) {
    return VaultFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      size: size ?? this.size,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

/// Vault file types for categorization
enum VaultFileType { photo, video, audio, document, other }

extension VaultFileTypeExtension on VaultFileType {
  String get displayName {
    switch (this) {
      case VaultFileType.photo:
        return 'Photos';
      case VaultFileType.video:
        return 'Videos';
      case VaultFileType.audio:
        return 'Audio';
      case VaultFileType.document:
        return 'Documents';
      case VaultFileType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case VaultFileType.photo:
        return Icons.image;
      case VaultFileType.video:
        return Icons.video_library;
      case VaultFileType.audio:
        return Icons.audio_file;
      case VaultFileType.document:
        return Icons.description;
      case VaultFileType.other:
        return Icons.insert_drive_file;
    }
  }

  static VaultFileType fromExtension(String extension) {
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return VaultFileType.photo;
    } else if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(ext)) {
      return VaultFileType.video;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(ext)) {
      return VaultFileType.audio;
    } else if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(ext)) {
      return VaultFileType.document;
    }
    return VaultFileType.other;
  }
}
