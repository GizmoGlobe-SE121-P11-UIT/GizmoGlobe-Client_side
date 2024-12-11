enum PSUEfficiency {
  white('80+ White'),
  bronze('80+ Bronze'),
  gold('80+ Gold'),
  platinum('80+ Platinum'),
  titanium('80+ Titanium');

  final String description;

  const PSUEfficiency(this.description);

  @override
  String toString() {
    return description;
  }
}