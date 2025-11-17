class CloudBackupConfig {
  final String email;
  final String frequency; // e.g. daily, weekly, monthly
  final bool wifiOnly;
  final bool includeHistory;
  final bool includeNotes;

  CloudBackupConfig({
    required this.email,
    required this.frequency,
    this.wifiOnly = true,
    this.includeHistory = true,
    this.includeNotes = true,
  });

  CloudBackupConfig copyWith({
    String? email,
    String? frequency,
    bool? wifiOnly,
    bool? includeHistory,
    bool? includeNotes,
  }) {
    return CloudBackupConfig(
      email: email ?? this.email,
      frequency: frequency ?? this.frequency,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      includeHistory: includeHistory ?? this.includeHistory,
      includeNotes: includeNotes ?? this.includeNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'frequency': frequency,
    'wifiOnly': wifiOnly,
    'includeHistory': includeHistory,
    'includeNotes': includeNotes,
  };

  factory CloudBackupConfig.fromJson(Map<String, dynamic> json) {
    return CloudBackupConfig(
      email: json['email'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'daily',
      wifiOnly: json['wifiOnly'] as bool? ?? true,
      includeHistory: json['includeHistory'] as bool? ?? true,
      includeNotes: json['includeNotes'] as bool? ?? true,
    );
  }
}
