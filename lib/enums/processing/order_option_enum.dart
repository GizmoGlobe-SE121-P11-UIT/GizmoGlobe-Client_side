enum OrderOption {
  toShip('To Ship'),
  toReceive('To Receive'),
  completed('Completed'),
  cancelled('Cancelled');

  final String description;

  const OrderOption(this.description);

  @override
  String toString() {
    return description;
  }
}
