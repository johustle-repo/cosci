import 'package:cloud_firestore/cloud_firestore.dart';

/// One row of the CCS student masterlist: the roster the verification
/// pipeline checks a scanned ID's student number against. The document id
/// in Firestore is the canonical student number itself ("YY-XX-NNNN").
class AdminMasterlistEntry {
  const AdminMasterlistEntry({
    required this.studentNumber,
    required this.name,
    required this.program,
    this.active = true,
    this.updatedAt,
  });

  final String studentNumber;
  final String name;
  final String program;
  final bool active;
  final DateTime? updatedAt;

  factory AdminMasterlistEntry.fromMap(String id, Map<String, dynamic> map) {
    return AdminMasterlistEntry(
      studentNumber: id,
      name: map['name'] as String? ?? '',
      program: map['program'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'program': program.trim(),
    'active': active,
  };

  AdminMasterlistEntry copyWith({String? name, String? program, bool? active}) {
    return AdminMasterlistEntry(
      studentNumber: studentNumber,
      name: name ?? this.name,
      program: program ?? this.program,
      active: active ?? this.active,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
