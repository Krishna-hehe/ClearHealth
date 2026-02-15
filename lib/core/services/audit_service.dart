enum AuditAction {
  loginSuccess,
  loginFailure,
  signupSuccess,
  signupFailure,
  googleSignInAttempt,
  appleSignInAttempt,
  viewLabResult,
  uploadLabResult,
  deleteLabResult,
}

class AuditService {
  Future<void> log(AuditAction action, {String? details}) async {
    // In a real app, this would write to a secure log or a service like Sentry.
    // For this example, we'll just print to the console.
    print('AUDIT: ${action.name} - ${details ?? ''}');
  }
}