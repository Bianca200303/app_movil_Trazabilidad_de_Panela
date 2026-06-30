class CertifiedWorker {
  final String id;
  final String firstName;
  final String lastName;
  final String? position;

  const CertifiedWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.position,
  });

  String get fullName => '$firstName $lastName';

  factory CertifiedWorker.fromJson(Map<String, dynamic> json) {
    return CertifiedWorker(
      id:        json['id']         as String,
      firstName: json['first_name'] as String,
      lastName:  json['last_name']  as String,
      position:  json['position']   as String?,
    );
  }
}
