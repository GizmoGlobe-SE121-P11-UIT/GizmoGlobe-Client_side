enum NotifyMessage {
  empty('', ''),
  msg1('Welcome back! You have successfully signed in.',
      'Chào mừng trở lại! Bạn đã đăng nhập thành công.'),
  msg2('Failed to sign in. Please try again.',
      'Đăng nhập thất bại. Vui lòng thử lại.'),
  msg3('Failed to send verification link. Please try again.',
      'Gửi liên kết xác thực thất bại. Vui lòng thử lại.'),
  msg4('Error changing password. Please try again.',
      'Lỗi khi thay đổi mật khẩu. Vui lòng thử lại.'),
  msg5('Passwords do not match.', 'Mật khẩu không khớp.'),
  msg6(
      'A verification email has been sent to your email address. Please verify your email to complete signing up.',
      'Email xác thực đã được gửi đến địa chỉ email của bạn. Vui lòng xác thực email để hoàn tất đăng ký.'),
  msg7('Failed to sign up. Please try again.',
      'Đăng ký thất bại. Vui lòng thử lại.'),
  msg8(
      'A verification link has been sent to your email address. Please verify your email to reset your password.',
      'Liên kết xác thực đã được gửi đến địa chỉ email của bạn. Vui lòng xác thực email để đặt lại mật khẩu.'),
  msg9('Failed to sign out. Please try again.',
      'Đăng xuất thất bại. Vui lòng thử lại.'),
  msg10('Email not verified. Please verify your email.',
      'Email chưa được xác thực. Vui lòng xác thực email của bạn.'),
  msg11('Guest Account Notice', 'Thông báo tài khoản khách'),
  msg12(
      'As a guest, you will have limited access to app features. Would you like to continue?',
      'Với tư cách khách, bạn sẽ chỉ có thể sử dụng các tính năng giới hạn của ứng dụng. Bạn có muốn tiếp tục?'),
  ;

  final String description;
  final String vietnameseDescription;

  const NotifyMessage(this.description, this.vietnameseDescription);

  @override
  String toString() {
    return description;
  }

  String toVietnameseString() {
    return vietnameseDescription;
  }
}
