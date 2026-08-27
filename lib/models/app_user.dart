class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'student',
    this.accountStatus = 'active',
    this.program,
    this.yearLevel,
    this.idVerificationStatus,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role;
  final String accountStatus;
  final String? program;
  final String? yearLevel;
  final String? idVerificationStatus;

  String get normalizedIdVerificationStatus =>
      (idVerificationStatus ?? 'legacy_approved').trim().toLowerCase();
  bool get requiresIdVerification =>
      isStudent &&
      normalizedIdVerificationStatus != 'approved' &&
      normalizedIdVerificationStatus != 'legacy_approved';

  String get normalizedRole {
    final value = role.trim().toLowerCase();
    if (const {'professor', 'teacher', 'faculty'}.contains(value)) {
      return 'instructor';
    }
    return value;
  }

  String get normalizedAccountStatus {
    final value = accountStatus.trim().toLowerCase();
    return const {'active', 'suspended', 'archived'}.contains(value)
        ? value
        : 'active';
  }

  bool get isAdmin => normalizedRole == 'admin';
  bool get isInstructor => normalizedRole == 'instructor';
  bool get isStudent => normalizedRole == 'student';
  bool get isActive => normalizedAccountStatus == 'active';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'accountStatus': accountStatus,
      'program': program,
      'yearLevel': yearLevel,
      'idVerificationStatus': idVerificationStatus,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? map['full_name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'student',
      accountStatus:
          map['accountStatus'] as String? ??
          map['account_status'] as String? ??
          ((map['isActive'] as bool? ?? true) ? 'active' : 'suspended'),
      program: map['program'] as String? ?? map['course'] as String?,
      yearLevel: map['yearLevel'] as String? ?? map['year_level'] as String?,
      idVerificationStatus: map['idVerificationStatus'] as String?,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    String? accountStatus,
    String? program,
    String? yearLevel,
    String? idVerificationStatus,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
    );
  }
}
