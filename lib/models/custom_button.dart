/// Model for custom calculator buttons
class CustomButton {
  final String id;
  final String label;
  final String action; // What to insert when button is pressed
  final String mode; // 'scientific', 'basic', or 'all'
  final int order; // Order in which to display

  CustomButton({
    required this.id,
    required this.label,
    required this.action,
    this.mode = 'scientific',
    this.order = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action': action,
      'mode': mode,
      'order': order,
    };
  }

  factory CustomButton.fromJson(Map<String, dynamic> json) {
    return CustomButton(
      id: json['id'] as String,
      label: json['label'] as String,
      action: json['action'] as String,
      mode: json['mode'] as String? ?? 'scientific',
      order: json['order'] as int? ?? 0,
    );
  }

  CustomButton copyWith({
    String? id,
    String? label,
    String? action,
    String? mode,
    int? order,
  }) {
    return CustomButton(
      id: id ?? this.id,
      label: label ?? this.label,
      action: action ?? this.action,
      mode: mode ?? this.mode,
      order: order ?? this.order,
    );
  }
}
