class Manufacturer {
  final String manufacturerID;
  final String manufacturerName;

  const Manufacturer({
    required this.manufacturerID,
    required this.manufacturerName,
  });

  static Manufacturer fromFirestore(String id, Map<String, dynamic> data) {
    return Manufacturer(
      manufacturerID: id,
      manufacturerName: data['manufacturerName'] ?? 'Unknown',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manufacturer &&
          runtimeType == other.runtimeType &&
          manufacturerID == other.manufacturerID;

  @override
  int get hashCode => manufacturerID.hashCode;
}