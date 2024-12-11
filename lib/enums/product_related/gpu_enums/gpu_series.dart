enum GPUSeries {
  gtx('GTX'),
  rtx('RTX'),
  quadro('Quadro'),
  rx('RX'),
  firePro('FirePro'),
  arc('Arc');

  final String description;

  const GPUSeries(this.description);

  @override
  String toString() {
    return description;
  }
}