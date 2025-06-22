import '../enums/manufacturer/manufacturer_status.dart';

class Manufacturer {
  final String? manufacturerID;
  final String manufacturerName;
  final ManufacturerStatus status;

  Manufacturer({
    this.manufacturerID,
    required this.manufacturerName,
    this.status = ManufacturerStatus.active,  // Default to active
  });

  static Manufacturer nullManufacturer = Manufacturer(
    manufacturerName: 'Unknown', // Không xác định
    manufacturerID: '',
    status: ManufacturerStatus.active,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manufacturer &&
          runtimeType == other.runtimeType &&
          manufacturerID == other.manufacturerID;

  @override
  int get hashCode => manufacturerID.hashCode;

  Manufacturer copyWith({
    String? manufacturerID,
    String? manufacturerName,
    ManufacturerStatus? status,
  }) {
    return Manufacturer(
      manufacturerID: manufacturerID ?? this.manufacturerID,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      status: status ?? this.status,
    );
  }
}