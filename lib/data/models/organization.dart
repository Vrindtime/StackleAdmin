import 'dart:convert';

class JobType {
  final String jobType;

  JobType({required this.jobType});

  factory JobType.fromJson(Map<String, dynamic> json) {
    return JobType(
      jobType: json['job_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_type': jobType,
    };
  }
}

class JobImage {
  final String url;

  JobImage({required this.url});

  factory JobImage.fromJson(Map<String, dynamic> json) {
    return JobImage(
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}

class JobSkill {
  final String skill;

  JobSkill({required this.skill});

  factory JobSkill.fromJson(Map<String, dynamic> json) {
    return JobSkill(
      skill: json['skill'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
    };
  }
}

class Job {
  final int organisationId;
  final String title;
  final String description;
  final String qualification;
  final int experienceYears;
  final String salary;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String phone;
  final String email;
  final bool isSubscribed;
  final List<JobType> jobTypes;
  final List<JobImage> jobImages;
  final List<JobSkill> jobSkills;

  Job({
    required this.organisationId,
    required this.title,
    required this.description,
    required this.qualification,
    required this.experienceYears,
    required this.salary,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.isSubscribed,
    required this.jobTypes,
    required this.jobImages,
    required this.jobSkills,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      organisationId: json['organisation_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      qualification: json['qualification'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      salary: json['salary'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isSubscribed: json['is_subscribed'] ?? false,
      jobTypes: (json['job_types'] as List<dynamic>?)
              ?.map((e) => JobType.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      jobImages: (json['job_images'] as List<dynamic>?)
              ?.map((e) => JobImage.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      jobSkills: (json['job_skills'] as List<dynamic>?)
              ?.map((e) => JobSkill.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organisation_id': organisationId,
      'title': title,
      'description': description,
      'qualification': qualification,
      'experience_years': experienceYears,
      'salary': salary,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'is_subscribed': isSubscribed,
      'job_types': jobTypes.map((e) => e.toJson()).toList(),
      'job_images': jobImages.map((e) => e.toJson()).toList(),
      'job_skills': jobSkills.map((e) => e.toJson()).toList(),
    };
  }
}

class Organization {
  final int id;
  final int userId;
  final String name;
  final String area;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String? phone;
  final String? email;
  final String latitude;
  final String longitude;
  final String description;
  final String? logo;
  final String registrationNumber;
  final List<String> document;
  final List<String> images;
  final int activeJobCount;
  final int requestsCount;
  final int searchAppearanceCount;
  final bool isAdminApproved;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.userId,
    required this.name,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.phone,
    this.email,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.logo,
    required this.registrationNumber,
    required this.document,
    required this.images,
    required this.activeJobCount,
    required this.requestsCount,
    required this.searchAppearanceCount,
    required this.isAdminApproved,
    required this.isBlocked,
    required this.createdAt,
    required this.updatedAt,
  });

  String get location => '$area, $city, $state';
  String get approvalStatus => isBlocked ? 'Blocked' : (isAdminApproved ? 'Approved' : 'Pending');

  /// If [value] is a media object Map (or JSON string), extract the url key; otherwise return as string.
  static String _extractUrl(dynamic value) {
    if (value is Map) return (value['url'] ?? '').toString();
    if (value is String && value.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) return (parsed['url'] ?? '').toString();
      } catch (_) {}
    }
    return value?.toString() ?? '';
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'],
      email: json['email'],
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      description: json['description'] ?? '',
      logo: _extractUrl(json['logo']),
      registrationNumber: json['registration_number'] ?? '',
      document: (json['document'] as List<dynamic>?)
              ?.map((e) => _extractUrl(e))
              .toList() ?? [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => _extractUrl(e))
              .toList() ?? [],
      activeJobCount: json['active_job_count'] ?? 0,
      requestsCount: json['requests_count'] ?? 0,
      searchAppearanceCount: json['search_appearance_count'] ?? 0,
      isAdminApproved: json['isAdminApproved'] ?? false,
      isBlocked: json['isBlocked'] ?? json['is_blocked'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'area': area,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'logo': logo,
      'registration_number': registrationNumber,
      'document': document,
      'images': images,
      'active_job_count': activeJobCount,
      'requests_count': requestsCount,
      'search_appearance_count': searchAppearanceCount,
      'isAdminApproved': isAdminApproved,
      'isBlocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}