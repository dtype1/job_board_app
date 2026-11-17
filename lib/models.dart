/// Modelli di dominio scambiati con il back-end.
library;

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.email,
    this.description = '',
  });

  final String id;
  final String name;
  final String email;
  final String description;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'email': email, 'description': description};
}

class Job {
  const Job({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.location,
    required this.contractType,
    required this.createdAt,
    this.applicationsCount,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String title;
  final String description;
  final String location;
  final String contractType;
  final DateTime createdAt;

  /// Presente solo negli elenchi dell'area riservata.
  final int? applicationsCount;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String? ?? '',
        contractType: json['contractType'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        applicationsCount: json['applicationsCount'] as int?,
      );
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.message,
    required this.cvFileName,
    required this.cvSize,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String message;
  final String cvFileName;
  final int cvSize;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        jobTitle: json['jobTitle'] as String? ?? '',
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        message: json['message'] as String? ?? '',
        cvFileName: json['cvFileName'] as String,
        cvSize: json['cvSize'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
