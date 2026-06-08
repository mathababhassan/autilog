sealed class LinkStatus {
  const LinkStatus();
}

class NoLink extends LinkStatus {
  const NoLink();
}

class PendingLink extends LinkStatus {
  const PendingLink({required this.requestId, required this.therapistEmail});
  final String requestId;
  final String therapistEmail;
}

class ActiveLink extends LinkStatus {
  const ActiveLink({
    required this.therapistId,
    required this.therapistName,
    required this.clinicName,
    required this.specialisation,
    this.phone,
  });
  final String therapistId;
  final String therapistName;
  final String clinicName;
  final String specialisation;
  final String? phone;
}
