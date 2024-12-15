enum DialogName {
  empty(''),
  success('Success'),
  failure('Failure'),
  confirm('Confirm'),
  ;

  final String description;
  const DialogName(this.description);
  @override
  String toString() {
    return description;
  }
}