class CollectionConfig {
  final String collectionPath;
  final String dateField;

  const CollectionConfig({
    required this.collectionPath,
    required this.dateField,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionConfig &&
        other.collectionPath == collectionPath &&
        other.dateField == dateField;
  }

  @override
  int get hashCode => collectionPath.hashCode ^ dateField.hashCode;
}