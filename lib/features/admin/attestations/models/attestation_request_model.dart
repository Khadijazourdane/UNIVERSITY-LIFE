import 'package:university_life/features/admin/services/admin_api.dart';
enum AttestationStatus {
  pending('En attente'),
  accepted('Acceptée'),
  refused('Refusée');
  const AttestationStatus(this.label);
  final String label;
  static AttestationStatus parse(String value) => switch (value) {
    'accepted' => AttestationStatus.accepted,
    'refused' => AttestationStatus.refused,
    _ => AttestationStatus.pending,
  };
}
class AttestationRequest {
  const AttestationRequest({
    required this.id,
    required this.studentName,
    required this.type,
    required this.requestedAt,
    required this.status,
    this.reason = '',
  });
  factory AttestationRequest.fromJson(Map<String, dynamic> json) =>
      AttestationRequest(
        id: asText(json['id']),
        studentName: asText(json['studentName']),
        type: asText(json['type']),
        requestedAt: asText(json['requestedAt']),
        status: AttestationStatus.parse(asText(json['status'])),
        reason: asText(json['reason']),
      );
  final String id;
  final String studentName;
  final String type;
  final String requestedAt;
  final AttestationStatus status;
  final String reason;
}
