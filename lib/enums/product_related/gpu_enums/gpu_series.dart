enum GPUSeries {
  unknown('Unknown'),
  gtx('GTX'),
  rtx('RTX'),
  quadro('Quadro'),
  rx('RX'),
  firePro('FirePro'),
  arc('Arc');

  final String description;

  const GPUSeries(this.description);

  String getName() {
    return name;
  }

  static List<GPUSeries> getValues() {
    return GPUSeries.values.where((e) => e != GPUSeries.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension GPUSeriesExtension on GPUSeries {
  static GPUSeries fromName(String name) {
    return GPUSeries.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => GPUSeries.unknown,
    );
  }
}