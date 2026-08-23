import 'package:cloud_firestore/cloud_firestore.dart';

/// Metadata for an uploaded programming course syllabus.
class AdminSyllabus {
  const AdminSyllabus({
    required this.id,
    required this.title,
    this.courseCode = '',
    this.courseName = '',
    this.programmingLanguage = '',
    this.yearLevel = '',
    this.term = '',
    this.fileUrl = '',
    this.fileType = '',
    this.fileName = '',
    this.fileSizeBytes = 0,
    this.uploadedBy = '',
    this.uploadedByEmail = '',
    this.analysisStatus = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String courseCode;
  final String courseName;
  final String programmingLanguage;
  final String yearLevel;
  final String term;
  final String fileUrl;
  final String fileType; // pdf | txt | docx
  final String fileName;
  final int fileSizeBytes;
  final String uploadedBy; // admin uid
  final String uploadedByEmail;

  /// pending | analyzing | analyzed | failed
  final String analysisStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAnalyzed => analysisStatus == 'analyzed';
  bool get isAnalyzing => analysisStatus == 'analyzing';
  bool get analysisFailed => analysisStatus == 'failed';
  bool get isPending => analysisStatus == 'pending';

  String get displayFileSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'courseCode': courseCode,
    'courseName': courseName,
    'programmingLanguage': programmingLanguage,
    'yearLevel': yearLevel,
    'term': term,
    'fileUrl': fileUrl,
    'fileType': fileType,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'uploadedBy': uploadedBy,
    'uploadedByEmail': uploadedByEmail,
    'analysisStatus': analysisStatus,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory AdminSyllabus.fromMap(String id, Map<String, dynamic> map) {
    return AdminSyllabus(
      id: id,
      title: map['title'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      programmingLanguage: map['programmingLanguage'] as String? ?? '',
      yearLevel: map['yearLevel'] as String? ?? '',
      term: map['term'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      fileType: map['fileType'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploadedByEmail: map['uploadedByEmail'] as String? ?? '',
      analysisStatus: map['analysisStatus'] as String? ?? 'pending',
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  AdminSyllabus copyWith({
    String? title,
    String? courseCode,
    String? courseName,
    String? programmingLanguage,
    String? yearLevel,
    String? term,
    String? fileUrl,
    String? fileType,
    String? fileName,
    int? fileSizeBytes,
    String? uploadedBy,
    String? uploadedByEmail,
    String? analysisStatus,
  }) {
    return AdminSyllabus(
      id: id,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      programmingLanguage: programmingLanguage ?? this.programmingLanguage,
      yearLevel: yearLevel ?? this.yearLevel,
      term: term ?? this.term,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByEmail: uploadedByEmail ?? this.uploadedByEmail,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
