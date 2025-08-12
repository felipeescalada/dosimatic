class Contact {
  final String idContact;
  final String firstName;
  final String lastName;
  final String businessName;
  final String email;
  final String phoneNumber;
  final int country;
  final int city;
  final String zipCode;
  final String frontPartUrl;
  final String backPartUrl;
  final DateTime createdAt;
  final int status;

  const Contact({
    required this.idContact,
    required this.firstName,
    required this.lastName,
    required this.businessName,
    required this.email,
    required this.phoneNumber,
    required this.country,
    required this.city,
    required this.zipCode,
    required this.frontPartUrl,
    required this.backPartUrl,
    required this.createdAt,
    this.status = 1,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      idContact: json['id_contact'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      businessName: json['business_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      country: json['country_id'] ?? 0,
      city: json['city_id'] ?? 0,
      zipCode: json['zip_code'] ?? '',
      frontPartUrl: json['front_part_url'] ?? '',
      backPartUrl: json['back_part_url'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idContact': idContact,
      'firstName': firstName,
      'lastName': lastName,
      'businessName': businessName,
      'email': email,
      'phoneNumber': phoneNumber,
      'country': country,
      'city': city,
      'zipCode': zipCode,
      'frontPartUrl': frontPartUrl,
      'backPartUrl': backPartUrl,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  String get fullName => '$firstName $lastName';
}
