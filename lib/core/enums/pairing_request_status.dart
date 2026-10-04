enum PairingRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static PairingRequestStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return PairingRequestStatus.approved;
      case 'rejected':
        return PairingRequestStatus.rejected;
      case 'cancelled':
        return PairingRequestStatus.cancelled;
      case 'pending':
      default:
        return PairingRequestStatus.pending;
    }
  }
}
