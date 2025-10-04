class ClientExperience {
  final String? title;
  final String? company;
  final String? duration;
  final String? description;
  final String? experienceCertificate;

  ClientExperience({
    this.title,
    this.company,
    this.duration,
    this.description,
    this.experienceCertificate,
  });

  factory ClientExperience.fromJson(Map<String, dynamic> json) {
    // Map backend keys (designation, employer, start_date, end_date, currently_working)
    String? start = json['start_date'];
    String? end = json['end_date'];
    final bool currentlyWorking = json['currently_working'] == true || json['currently_working'] == 'true';

    String computeDuration() {
      if (start == null && end == null) return '';
      if (start != null && currentlyWorking) return '$start - Present';
      if (start != null && end != null) return '$start - $end';
      if (start == null && end != null) return 'Until $end';
      return '';
    }

    return ClientExperience(
      title: json['designation'] ?? json['title'],
      company: json['employer'] ?? json['company'],
      duration: computeDuration(),
      description: json['location'] ?? json['description'],
      experienceCertificate: json['experience_certificate'] ?? json['experienceCertificate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'duration': duration,
      'description': description,
      'experience_certificate': experienceCertificate,
    };
  }
}

class ClientCertificate {
  final String? name;
  final String? issuer;
  final String? issueDate;
  final String? certificateUrl;

  ClientCertificate({
    this.name,
    this.issuer,
    this.issueDate,
    this.certificateUrl,
  });

  factory ClientCertificate.fromJson(Map<String, dynamic> json) {
    return ClientCertificate(
      name: json['name'],
      issuer: json['issuer'],
      issueDate: json['issue_date'],
      certificateUrl: json['certificate_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'issue_date': issueDate,
      'certificate_url': certificateUrl,
    };
  }
}

class ClientEducation {
  final String? institution;
  final String? degree;
  final String? fieldOfStudy;
  final String? startDate;
  final String? endDate;
  final String? grade;
  final String? certificate;

  ClientEducation({
    this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.grade,
    this.certificate,
  });

  factory ClientEducation.fromJson(Map<String, dynamic> json) {
    return ClientEducation(
      institution: json['university'],
      degree: json['degree'],
      fieldOfStudy: json['field_of_study'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      grade: json['grade'],
      certificate: json['certificate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'university': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_date': startDate,
      'end_date': endDate,
      'grade': grade,
      'certificate': certificate,
    };
  }
}

class ClientLanguage {
  final String? language;

  ClientLanguage({
    this.language,
  });

  factory ClientLanguage.fromJson(Map<String, dynamic> json) {
    return ClientLanguage(
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
    };
  }
}

class Client {
  final int clientId;
  final int userId;
  final bool isKycVerified;
  final bool isAdminApproved;
  final String? preferredJob;
  final DateTime? dob;
  final String? gender;
  final String? place;
  final String? district;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? resume;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ClientExperience> experiences;
  final List<ClientCertificate> certificates;
  final List<ClientEducation> education;
  final List<ClientLanguage> languages;
  final String? description;

  Client({
    required this.clientId,
    required this.userId,
    required this.isKycVerified,
    required this.isAdminApproved,
    this.preferredJob,
    this.dob,
    this.gender,
    this.place,
    this.district,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.resume,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.experiences,
    required this.certificates,
    required this.education,
    required this.languages,
    this.description,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      clientId: json['client_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      isKycVerified: json['is_kyc_verified'] ?? false,
      isAdminApproved: json['isAdminApproved'] ?? false,
      preferredJob: json['preferred_job'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'],
      place: json['place'],
      district: json['district'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      resume: json['resume'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      experiences: (json['experiences'] as List<dynamic>?)
          ?.map((e) => ClientExperience.fromJson(e))
          .toList() ?? [],
      certificates: (json['certificates'] as List<dynamic>?)
          ?.map((e) => ClientCertificate.fromJson(e))
          .toList() ?? [],
      education: (json['education'] as List<dynamic>?)
          ?.map((e) => ClientEducation.fromJson(e))
          .toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => ClientLanguage.fromJson(e))
          .toList() ?? [],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'user_id': userId,
      'is_kyc_verified': isKycVerified,
      'isAdminApproved': isAdminApproved,
      'preferred_job': preferredJob,
      'dob': dob?.toIso8601String().split('T')[0],
      'gender': gender,
      'place': place,
      'district': district,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'resume': resume,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'certificates': certificates.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'languages': languages.map((e) => e.toJson()).toList(),
      'description': description,
    };
  }

  // Helper getters for UI
  String get location => [place, district, state].where((s) => s != null && s.isNotEmpty).join(', ');
  String get formattedCreatedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year} - ${createdAt.hour.toString().padLeft(2, '0')}.${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour >= 12 ? 'PM' : 'AM'}';
  }
  
  bool get isPendingApproval => !isAdminApproved;
  String get approvalStatus => isAdminApproved ? 'Approved' : 'Rejected';
}