import '../models/student_model.dart';

/// Données fictives en mémoire.
/// À remplacer par des appels à `ApiClient` quand le contrat backend sera défini.
class TeacherStudentService {
  static const List<StudentModel> _students = [
    StudentModel(
      id: 's1',
      fullName: 'Amina Benali',
      email: 'amina.benali@univ.ma',
      filiere: 'Informatique',
      group: 'G1',
    ),
    StudentModel(
      id: 's2',
      fullName: 'Youssef El Idrissi',
      email: 'youssef.elidrissi@univ.ma',
      filiere: 'Informatique',
      group: 'G1',
    ),
    StudentModel(
      id: 's3',
      fullName: 'Salma Ouahbi',
      email: 'salma.ouahbi@univ.ma',
      filiere: 'Informatique',
      group: 'G2',
    ),
    StudentModel(
      id: 's4',
      fullName: 'Omar Tazi',
      email: 'omar.tazi@univ.ma',
      filiere: 'Informatique',
      group: 'G2',
    ),
  ];

  Future<List<StudentModel>> fetchStudents(String moduleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _students;
  }
}
