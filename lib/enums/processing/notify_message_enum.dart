enum NotifyMessage {
  empty(''),
  msg1('Signed in successfully.'),
  msg2('Failed to sign in. Please try again.'),
  msg3('Failed to send verification link. Please try again.'),
  msg4('Error changing password. Please try again.'),
  msg5('Passwords do not match.'),
  msg6('A verification email has been sent to your email address. Please verify your email to complete signing up.'),
  msg7('Failed to sign up. Please try again.'),
  msg8('A verification link has been sent to your email address. Please verify your email to reset your password.'),
  msg9('Failed to sign out. Please try again.'),
  ;

  final String description;
  const NotifyMessage(this.description);
  @override
  String toString() {
    return description;
  }
}