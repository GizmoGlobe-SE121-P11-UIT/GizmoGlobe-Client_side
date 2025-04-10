enum OrderOption {
  toShip('To Ship'),
  toReceive('To Receive'),
  completed('Completed');

  final String description;

  const OrderOption(this.description);

  @override
  String toString() {
    return description;
  }
}
