enum GPUSeries {
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

  @override
  String toString() {
    return description;
  }
}

extension GPUSeriesExtension on GPUSeries {
  static GPUSeries fromName(String name) {
    return GPUSeries.values.firstWhere((e) => e.getName() == name);
  }
}