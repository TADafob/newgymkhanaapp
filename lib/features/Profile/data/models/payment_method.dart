class PaymentMethod {
  final String id;
  final String type; // 'mpesa' | 'airtel' | 'card'
  final String label;
  final String identifier; // phone number or masked card e.g. **** 4242
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.identifier,
    required this.isDefault,
  });

  factory PaymentMethod.fromMap(String id, Map<String, dynamic> data) {
    return PaymentMethod(
      id: id,
      type: data['type'] as String? ?? '',
      label: data['label'] as String? ?? '',
      identifier: data['identifier'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'label': label,
        'identifier': identifier,
        'isDefault': isDefault,
      };
}
