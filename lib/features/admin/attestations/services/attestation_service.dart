import 'package:university_life/features/admin/attestations/models/attestation_request_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';

class AttestationService {
  AttestationService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/attestations';

  final AdminApi _api;

  Future<List<AttestationRequest>> fetchAll() async {
    final requests = await _api.fetchAll(_path, AttestationRequest.fromJson);
    final pending = requests.where(
          (request) => request.status == AttestationStatus.pending,
    );
    final processed = requests.where(
          (request) => request.status != AttestationStatus.pending,
    );
    return [...pending, ...processed];
  }

  Future<void> accept(String id) =>
      _api.put('$_path/$id', {'status': 'accepted'});

  Future<void> refuse(String id, {String reason = ''}) =>
      _api.put('$_path/$id', {'status': 'refused', 'reason': reason});
}
