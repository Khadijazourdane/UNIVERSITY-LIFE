import 'package:flutter/foundation.dart';

import '../models/teacher_module_model.dart';
import '../services/teacher_module_service.dart';

class TeacherModuleProvider extends ChangeNotifier {
  TeacherModuleProvider(this._service);

  final TeacherModuleService _service;

  List<TeacherModule> modules = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      modules = await _service.fetchModules();
    } catch (_) {
      error = 'Impossible de charger vos modules.';
    }
    isLoading = false;
    notifyListeners();
  }
}
