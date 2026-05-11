/// Maps Firebase Auth error codes to human-readable messages.
String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 8 characters.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network and try again.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
