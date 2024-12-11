enum PSUModular {
  nonModular('Non-Modular'),
  semiModular('Semi-Modular'),
  fullModular('Full-Modular');

  final String description;

  const PSUModular(this.description);

  @override
  String toString() {
    return description;
  }
}