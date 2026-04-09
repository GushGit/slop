class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.method,
    required this.addedCount,
    required this.scannedAt,
  });

  final String method;
  final int addedCount;
  final DateTime scannedAt;
}
