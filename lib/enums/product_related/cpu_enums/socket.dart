enum Socket {
  unknown('Unknown'),
  lga1700('LGA 1700'),
  lga1200('LGA 1200'),
  lga1151('LGA 1151'),
  lga1150('LGA 1150'),
  am4('AM4'),
  am5('AM5'),
  tr4('TR4'),
  sTRX4('sTRX4'),
  sWRX8('sWRX8'),
  sp3('SP3'),
  sp5('SP5');

  final String description;

  const Socket(this.description);

  String getName() {
    return name;
  }

  static List<Socket> getValues() {
    return Socket.values.where((e) => e != Socket.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension SocketExtension on Socket {
  static Socket fromName(String name) {
    return Socket.values.firstWhere(
        (e) => e.getName() == name,
        orElse: () => Socket.unknown
    );
  }
}

